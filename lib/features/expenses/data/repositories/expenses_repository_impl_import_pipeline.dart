part of 'expenses_repository_impl.dart';

/// Rows fetched from the queue per loop iteration. Small enough to keep peak
/// memory bounded; large enough for the isolate pool to saturate all workers.
const int _queueDrainBatchSize = 500;

/// Maximum number of queued rows to parse in one isolate job.
const int _queueProcessChunkSize = 100;

class _DirectInsert {
  _DirectInsert(this.queueId, this.candidate);

  final int queueId;
  final ParsedMpesaCandidate candidate;
}

Future<int> _processDueQueueImpl(
  ExpensesRepositoryImpl repo, {
  DateTime? from,
  void Function(int done, int total)? onProgress,
}) async {
  // Snapshot `now` once so every iteration uses the same retry-eligibility
  // cutoff — rows that fail and get a future next_retry_at won't re-appear
  // in this drain cycle.
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  // Count pending rows upfront so the progress bar can show a meaningful
  // fraction across the full queue, not just the current batch.
  final countRows = await repo._store.executor.runSelect(
    'SELECT COUNT(*) AS c FROM sms_import_queue '
    'WHERE scope = ? AND status IN (?, ?) AND (next_retry_at IS NULL OR next_retry_at <= ?)',
    ['local', 'pending', 'retry', nowMs],
  );
  final totalCount = repo._asInt(countRows.firstOrNull?['c'] ?? 0);
  if (totalCount == 0) return 0;

  var totalImported = 0;
  var totalDone = 0;

  // Create the isolate pool once for the entire drain — reusing the same
  // workers across all loop iterations avoids the heavy spawn/teardown cost
  // on every batch (critical for imports of 10 000+ messages).
  final pool = repo.useIsolatePool ? ParseIsolatePool() : null;
  try {
    // Loop until the queue is empty — handles arbitrarily large inboxes without
    // requiring manual "Retry now" taps. Each iteration fetches _queueDrainBatchSize
    // rows so peak memory stays bounded regardless of inbox size.
    while (true) {
      final rows = await repo._store.executor.runSelect(
        'SELECT id, raw_message, attempt, source_timestamp '
        'FROM sms_import_queue '
        'WHERE scope = ? AND status IN (?, ?) AND (next_retry_at IS NULL OR next_retry_at <= ?) '
        'ORDER BY created_at ASC LIMIT ?',
        ['local', 'pending', 'retry', nowMs, _queueDrainBatchSize],
      );
      if (rows.isEmpty) break;

      // P6: parse the whole batch in parallel across the reused isolate pool,
      // then persist chunk-by-chunk. parseAll spreads the batch across all workers.
      List<ParsedMpesaCandidate?>? allCandidates;
      if (pool != null && rows.length >= _queueProcessChunkSize) {
        final allJobs = rows
            .map((row) => _jobForRow(repo, row))
            .toList(growable: false);
        // Aligned 1:1 with rows, in order — safe to slice per chunk below.
        allCandidates = await pool.parseAll(
          allJobs,
          chunkSize: _queueProcessChunkSize,
        );
      }

      for (var i = 0; i < rows.length; i += _queueProcessChunkSize) {
        final end = (i + _queueProcessChunkSize).clamp(0, rows.length);
        final chunk = rows.sublist(i, end);
        final preParsed = allCandidates?.sublist(i, end);
        try {
          totalImported += await _processQueueChunk(
            repo,
            chunk,
            from: from,
            preParsed: preParsed,
          );
        } catch (error) {
          // If a batch fails (e.g. constraint violation in one row), fall back
          // to the one-by-one path so retries and per-row failures work.
          totalImported +=
              await _processQueueChunkRowByRow(repo, chunk, from: from);
        }
        totalDone = (totalDone + chunk.length).clamp(0, totalCount);
        onProgress?.call(totalDone, totalCount);
        // Yield to the UI thread between chunks so the app stays responsive
        // during large (e.g. multi-year) imports.
        await Future<void>.delayed(Duration.zero);
      }

      // Emit after each batch so the UI reflects newly imported transactions
      // incrementally rather than only at the very end of a large queue.
      repo._store.emitChange();
    }
  } finally {
    await pool?.dispose();
  }

  return totalImported;
}

/// Builds the parse job for a queue row (raw body + source-timestamp fallback).
SmsParseJob _jobForRow(ExpensesRepositoryImpl repo, Map<String, Object?> row) {
  final raw = '${row['raw_message'] ?? ''}';
  final sourceTimestampRaw = row['source_timestamp'];
  final fallback = sourceTimestampRaw == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(repo._asInt(sourceTimestampRaw));
  return SmsParseJob(raw, fallbackOccurredAt: fallback);
}

Future<int> _processQueueChunk(
  ExpensesRepositoryImpl repo,
  List<Map<String, Object?>> rows, {
  DateTime? from,
  List<ParsedMpesaCandidate?>? preParsed,
}) async {
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  // Aligned parse: candidates[i] corresponds 1:1 to rows[i] (with `null` for
  // unparseable rows). [preParsed] is supplied when the whole drain was parsed
  // up front through the isolate pool; otherwise parse this chunk now. Mapping
  // by index is only safe because the list is guaranteed 1:1 with rows — the
  // non-aligned parseJobsInIsolate dropped nulls and would misalign every
  // subsequent row after the first unparseable message.
  final candidates = preParsed ??
      await MpesaParserService.parseJobsInIsolateAligned(
        rows.map((row) => _jobForRow(repo, row)).toList(growable: false),
      );
  final candidateByQueueId = <int, ParsedMpesaCandidate>{};
  for (var i = 0; i < rows.length && i < candidates.length; i++) {
    final candidate = candidates[i];
    if (candidate == null) continue;
    candidateByQueueId[repo._asInt(rows[i]['id'])] = candidate;
  }

  // Batch-pre-fetch dedup state for the whole chunk — 2 DB round-trips
  // instead of 3 per row. Must happen after candidates are known.
  final duplicateSet = await _DuplicateSet.forCandidates(repo, candidates);

  final directRows = <_DirectInsert>[];
  final reviewBatch = <List<Object?>>[];
  final quarantineBatch = <List<Object?>>[];
  final auditBatch = <List<Object?>>[];
  final queueUpdateBatch = <List<Object?>>[];
  final acceptedCandidates = <ParsedMpesaCandidate>[];
  var imported = 0;

  for (final row in rows) {
    final queueId = repo._asInt(row['id']);
    var attempt = repo._asInt(row['attempt']);
    if (attempt < 0) {
      attempt = 0;
    } else if (attempt > 999) {
      attempt = 999;
    }

    try {
      final candidate = candidateByQueueId[queueId];

      if (candidate == null) {
        await _markDoneImpl(
          repo,
          queueId,
          status: 'failed',
          lastError: 'Unparseable',
        );
        continue;
      }

      if (from != null && candidate.occurredAt.isBefore(from)) {
        queueUpdateBatch.add(['skipped', nowMs, null, queueId]);
        continue;
      }

      if (duplicateSet.contains(candidate) ||
          _isDuplicateInChunk(candidate, acceptedCandidates)) {
        auditBatch.add(_auditRow(candidate, 'duplicate'));
        queueUpdateBatch.add(['duplicate', nowMs, null, queueId]);
        continue;
      }

      switch (candidate.route) {
        case MpesaParseRoute.directLedger:
          directRows.add(_DirectInsert(queueId, candidate));
          acceptedCandidates.add(candidate);
          // Count only after the row is successfully written below.
        case MpesaParseRoute.reviewQueue:
          reviewBatch.add(_reviewRow(candidate));
          auditBatch.add(_auditRow(candidate, 'review_pending'));
          queueUpdateBatch.add(['done', nowMs, null, queueId]);
          acceptedCandidates.add(candidate);
        case MpesaParseRoute.quarantine:
          quarantineBatch.add(_quarantineRow(candidate));
          auditBatch.add(_auditRow(candidate, 'quarantined'));
          queueUpdateBatch.add(['done', nowMs, null, queueId]);
          acceptedCandidates.add(candidate);
      }
    } catch (error) {
      await _handleQueueRowError(repo, queueId, attempt, error);
    }
  }

  final transactionBatch = <List<Object?>>[];
  final incomeBatch = <List<Object?>>[];
  var hasFulizaEvents = false;

  for (final direct in directRows) {
    final queueId = direct.queueId;
    final candidate = direct.candidate;
    try {
      // A Fuliza limit notice ("Your available Fuliza M-PESA limit is Ksh X")
      // carries no ledger transaction, but it updates the tracked limit.
      // Persist it so the Fuliza card reflects the latest value after import.
      final parsedLimit = candidate.fulizaAvailableLimitKes;
      if (parsedLimit != null && parsedLimit > 0) {
        await _persistFulizaLimitIfHigher(parsedLimit);
      }
      // The authoritative outstanding balance stated in a charge notice or
      // limit summary ("Total Fuliza M-PESA outstanding amount is Ksh X") is
      // far more accurate than summing draw/repayment events. Persist it.
      final parsedOutstanding = candidate.fulizaOutstandingKes;
      if (parsedOutstanding != null && parsedOutstanding >= 0) {
        await _persistFulizaOutstanding(parsedOutstanding);
      }
      final isFulizaType =
          candidate.transactionType == MpesaTransactionType.fulizaDraw ||
          candidate.transactionType == MpesaTransactionType.fulizaRepayment ||
          candidate.transactionType == MpesaTransactionType.fulizaCharge;
      if (isFulizaType) hasFulizaEvents = true;

      if (candidate.transactionType == MpesaTransactionType.fulizaCharge) {
        // reconcile: false — reconcile once per chunk below after all writes.
        await _upsertPaybillAndFulizaImpl(repo, candidate, reconcile: false);
        auditBatch.add(_auditRow(candidate, 'fuliza_balance_update'));
        queueUpdateBatch.add(['done', nowMs, null, queueId]);
        imported += 1;
        continue;
      }

      final learnedCategory = await _resolveLearnedCategoryImpl(
        repo,
        merchantTitle: candidate.title,
        fallbackCategory: candidate.category,
        amountKes: candidate.amountKes,
      );
      await _learnMerchantCategoryImpl(
        repo,
        merchantTitle: candidate.title,
        category: learnedCategory,
      );
      // reconcile: false — reconcile once per chunk below after all writes.
      await _upsertPaybillAndFulizaImpl(repo, candidate, reconcile: false);
      transactionBatch.add([
        candidate.title,
        learnedCategory,
        candidate.amountKes,
        candidate.occurredAt.millisecondsSinceEpoch,
        'sms',
        candidate.sourceHash,
        candidate.transactionType.name,
        candidate.balanceAfterKes,
        candidate.rawMessage,
        candidate.mpesaCode,
        candidate.feeKes,
      ]);
      if (_shouldCreateIncome(candidate)) {
        incomeBatch.add([
          candidate.title,
          candidate.amountKes,
          candidate.occurredAt.millisecondsSinceEpoch,
          'sms',
          candidate.sourceHash,
        ]);
      }
      auditBatch.add(_auditRow(candidate, 'imported'));
      queueUpdateBatch.add(['done', nowMs, null, queueId]);
      imported += 1;
    } catch (error) {
      var attempt = repo._asInt(
        rows.firstWhere((r) => repo._asInt(r['id']) == queueId)['attempt'],
      );
      if (attempt < 0) {
        attempt = 0;
      } else if (attempt > 999) {
        attempt = 999;
      }
      await _handleQueueRowError(repo, queueId, attempt, error);
    }
  }

  // Wrap all six batch writes in a SAVEPOINT so they're atomic: either every
  // table is updated or none are (preventing partially-imported chunks that
  // would re-process on the next drain and produce double entries).
  try {
    await repo._store.inTransaction(() async {
      if (transactionBatch.isNotEmpty) {
        await repo._store.addTransactionsBatch(transactionBatch);
      }
      if (incomeBatch.isNotEmpty) {
        await repo._store.insertIncomeBatch(incomeBatch);
      }
      if (reviewBatch.isNotEmpty) {
        await repo._store.insertSmsReviewBatch(reviewBatch);
      }
      if (quarantineBatch.isNotEmpty) {
        await repo._store.insertSmsQuarantineBatch(quarantineBatch);
      }
      if (auditBatch.isNotEmpty) {
        await repo._store.insertSmsImportAuditBatch(auditBatch);
      }
      if (queueUpdateBatch.isNotEmpty) {
        await repo._store.updateSmsImportQueueStatusBatch(queueUpdateBatch);
      }
    });
  } catch (error) {
    // DB-level batch failure: fall back to row-by-row so each row can retry
    // or fail individually without losing the whole chunk.
    return _processQueueChunkRowByRow(repo, rows, from: from);
  }

  // Reconcile Fuliza draw↔repayment links once per chunk (not per candidate)
  // so the O(N) reconcile query runs at most once regardless of how many
  // Fuliza events were in this batch.
  if (hasFulizaEvents) {
    await _reconcileFulizaLinksImpl(repo);
  }

  return imported;
}

bool _isDuplicateInChunk(
  ParsedMpesaCandidate candidate,
  List<ParsedMpesaCandidate> accepted,
) {
  for (final other in accepted) {
    if (candidate.sourceHash == other.sourceHash ||
        candidate.semanticHash == other.semanticHash) {
      return true;
    }
    final sameTitle =
        candidate.title.toLowerCase() == other.title.toLowerCase();
    final sameDay = candidate.occurredAt.year == other.occurredAt.year &&
        candidate.occurredAt.month == other.occurredAt.month &&
        candidate.occurredAt.day == other.occurredAt.day;
    final nearAmount = (candidate.amountKes - other.amountKes).abs() <= 1.0;
    if (sameTitle && sameDay && nearAmount) {
      return true;
    }
  }
  return false;
}

/// Batch-pre-fetched dedup guard for a chunk of parsed candidates. Replaces
/// per-row `_isDuplicateImpl` (3 DB round-trips per candidate) with 2 batch
/// queries for the whole chunk — O(1) round-trips regardless of chunk size.
class _DuplicateSet {
  _DuplicateSet._(this._sourceHashes, this._semanticHashes);

  final Set<String> _sourceHashes;
  final Set<String> _semanticHashes;

  bool contains(ParsedMpesaCandidate c) =>
      _sourceHashes.contains(c.sourceHash) ||
      _semanticHashes.contains(c.semanticHash);

  static Future<_DuplicateSet> forCandidates(
    ExpensesRepositoryImpl repo,
    List<ParsedMpesaCandidate?> candidates,
  ) async {
    final sourceHashes = candidates
        .whereType<ParsedMpesaCandidate>()
        .map((c) => c.sourceHash)
        .toSet()
        .toList();
    final semanticHashes = candidates
        .whereType<ParsedMpesaCandidate>()
        .map((c) => c.semanticHash)
        .toSet()
        .toList();

    final importedSrc = <String>{};
    const batchSize = 500;
    for (var i = 0; i < sourceHashes.length; i += batchSize) {
      final chunk = sourceHashes.sublist(
        i,
        (i + batchSize).clamp(0, sourceHashes.length),
      );
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await repo._store.executor.runSelect(
        'SELECT source_hash FROM transactions WHERE source_hash IN ($placeholders)',
        chunk,
      );
      for (final row in rows) {
        importedSrc.add('${row['source_hash']}');
      }
    }

    final auditedSem = <String>{};
    for (var i = 0; i < semanticHashes.length; i += batchSize) {
      final chunk = semanticHashes.sublist(
        i,
        (i + batchSize).clamp(0, semanticHashes.length),
      );
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await repo._store.executor.runSelect(
        'SELECT DISTINCT semantic_hash FROM sms_import_audit '
        'WHERE scope = ? AND semantic_hash IN ($placeholders) AND decision IN (?, ?, ?)',
        ['local', ...chunk, 'imported', 'duplicate', 'review_pending'],
      );
      for (final row in rows) {
        auditedSem.add('${row['semantic_hash']}');
      }
    }

    return _DuplicateSet._(importedSrc, auditedSem);
  }
}

Future<void> _handleQueueRowError(
  ExpensesRepositoryImpl repo,
  int queueId,
  int attempt,
  Object error,
) async {
  final nextAttempt = attempt + 1;
  if (nextAttempt >= 5) {
    await _markDoneImpl(
      repo,
      queueId,
      status: 'failed',
      lastError: '$error',
    );
    return;
  }
  final retryAt = DateTime.now().add(
    Duration(minutes: (1 << nextAttempt.clamp(0, 5))),
  );
  await repo._store.executor.runUpdate(
    'UPDATE sms_import_queue SET status = ?, attempt = ?, next_retry_at = ?, updated_at = ?, last_error = ? WHERE id = ?',
    [
      'retry',
      nextAttempt,
      retryAt.millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
      '$error',
      queueId,
    ],
  );
}

List<Object?> _reviewRow(ParsedMpesaCandidate candidate) {
  return [
    'local',
    candidate.sourceHash,
    candidate.semanticHash,
    candidate.title,
    candidate.category,
    candidate.amountKes,
    candidate.occurredAt.millisecondsSinceEpoch,
    candidate.rawMessage,
    candidate.confidenceScore,
    'pending',
    DateTime.now().millisecondsSinceEpoch,
  ];
}

List<Object?> _quarantineRow(ParsedMpesaCandidate candidate) {
  return [
    'local',
    candidate.sourceHash,
    candidate.semanticHash,
    candidate.rawMessage,
    candidate.reason ?? 'Low confidence classification',
    candidate.confidenceScore,
    'pending',
    DateTime.now().millisecondsSinceEpoch,
    candidate.title,
    candidate.category,
    candidate.amountKes,
    candidate.occurredAt.millisecondsSinceEpoch,
  ];
}

List<Object?> _auditRow(ParsedMpesaCandidate candidate, String decision) {
  return [
    'local',
    candidate.sourceHash,
    candidate.semanticHash,
    candidate.route.name,
    candidate.confidenceScore,
    decision,
    'done',
    jsonEncode(_auditPayloadForCandidate(candidate)),
    DateTime.now().millisecondsSinceEpoch,
  ];
}

Future<int> _processQueueChunkRowByRow(
  ExpensesRepositoryImpl repo,
  List<Map<String, Object?>> rows, {
  DateTime? from,
}) async {
  var imported = 0;
  for (final row in rows) {
    final queueId = repo._asInt(row['id']);
    final rawMessage = '${row['raw_message'] ?? ''}';
    final sourceTimestampRaw = row['source_timestamp'];
    final fallbackOccurredAt = sourceTimestampRaw == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(repo._asInt(sourceTimestampRaw));
    var attempt = repo._asInt(row['attempt']);
    if (attempt < 0) {
      attempt = 0;
    } else if (attempt > 999) {
      attempt = 999;
    }
    try {
      final candidate =
          repo._parser.parseSingleDetailed(
            rawMessage,
            fallbackOccurredAt: fallbackOccurredAt,
          ) ??
          repo._parser.parseSingleDetailed(
            'UNKNOWN Confirmed. Ksh0.00 $rawMessage',
            fallbackOccurredAt: fallbackOccurredAt,
          );
      if (candidate == null) {
        await _markDoneImpl(
          repo,
          queueId,
          status: 'failed',
          lastError: 'Unparseable',
        );
        continue;
      }
      if (from != null && candidate.occurredAt.isBefore(from)) {
        await _markDoneImpl(repo, queueId, status: 'skipped');
        continue;
      }
      if (await _isDuplicateImpl(repo, candidate)) {
        await _logAuditImpl(
          repo,
          sourceHash: candidate.sourceHash,
          semanticHash: candidate.semanticHash,
          route: candidate.route.name,
          confidence: candidate.confidenceScore,
          decision: 'duplicate',
          status: 'done',
          payload: _auditPayloadForCandidate(candidate),
        );
        await _markDoneImpl(repo, queueId, status: 'duplicate');
        continue;
      }
      switch (candidate.route) {
        case MpesaParseRoute.directLedger:
          await _insertDirectImpl(repo, candidate);
          imported += 1;
        case MpesaParseRoute.reviewQueue:
          await _insertReviewImpl(repo, candidate);
        case MpesaParseRoute.quarantine:
          await _insertQuarantineImpl(repo, candidate);
      }
      await _markDoneImpl(repo, queueId, status: 'done');
    } catch (error) {
      final nextAttempt = attempt + 1;
      if (nextAttempt >= 5) {
        await _markDoneImpl(
          repo,
          queueId,
          status: 'failed',
          lastError: '$error',
        );
        continue;
      }
      final retryAt = DateTime.now().add(
        Duration(minutes: (1 << nextAttempt.clamp(0, 5))),
      );
      await repo._store.executor.runUpdate(
        'UPDATE sms_import_queue SET status = ?, attempt = ?, next_retry_at = ?, updated_at = ?, last_error = ? WHERE id = ?',
        [
          'retry',
          nextAttempt,
          retryAt.millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch,
          '$error',
          queueId,
        ],
      );
    }
  }
  return imported;
}

Future<int> _replayImportQueueImpl(ExpensesRepositoryImpl repo) async {
  await repo._store.ensureInitialized();
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  await repo._store.executor.runUpdate(
    'UPDATE sms_import_queue '
    'SET status = ?, attempt = 0, next_retry_at = NULL, updated_at = ?, last_error = NULL '
    'WHERE scope = ? AND status IN (?, ?)',
    ['pending', nowMs, 'local', 'retry', 'failed'],
  );
  return _processDueQueueImpl(repo);
}

/// Persists a Fuliza available-limit value parsed from SMS, only raising the
/// stored limit (a limit increase notice is authoritative; never lower it
/// from an older message that imported out of order).
Future<void> _persistFulizaLimitIfHigher(double limit) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getDouble('fuliza_limit') ?? 0.0;
  if (limit > current) {
    await prefs.setDouble('fuliza_limit', limit);
  }
}

/// Persists the authoritative Fuliza outstanding balance stated in a charge
/// notice or limit summary. Uses the *most recent* value (not the max), since
/// outstanding decreases as the user repays and a stale higher value would be
/// wrong.
Future<void> _persistFulizaOutstanding(double outstanding) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('fuliza_outstanding', outstanding);
}

Future<void> _insertDirectImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
  // Fuliza charge notices update the outstanding balance only — they are not
  // ledger transactions.  Record them in fuliza_lifecycle_events and return.
  if (candidate.transactionType == MpesaTransactionType.fulizaCharge) {
    await _upsertPaybillAndFulizaImpl(repo, candidate);
    await _logAuditImpl(
      repo,
      sourceHash: candidate.sourceHash,
      semanticHash: candidate.semanticHash,
      route: candidate.route.name,
      confidence: candidate.confidenceScore,
      decision: 'fuliza_balance_update',
      status: 'done',
      payload: _auditPayloadForCandidate(candidate),
    );
    return;
  }
  final learnedCategory = await _resolveLearnedCategoryImpl(
    repo,
    merchantTitle: candidate.title,
    fallbackCategory: candidate.category,
    amountKes: candidate.amountKes,
  );
  await repo._store.addTransaction(
    title: candidate.title,
    category: learnedCategory,
    amountKes: candidate.amountKes,
    occurredAt: candidate.occurredAt,
    source: 'sms',
    sourceHash: candidate.sourceHash,
    transactionType: candidate.transactionType.name,
    balanceAfterKes: candidate.balanceAfterKes,
    feeKes: candidate.feeKes,
    rawSms: candidate.rawMessage,
    mpesaCode: candidate.mpesaCode,
  );
  if (_shouldCreateIncome(candidate)) {
    await _insertIncomeBatchImpl(repo, [
      [
        candidate.title,
        candidate.amountKes,
        candidate.occurredAt.millisecondsSinceEpoch,
        'sms',
        candidate.sourceHash,
      ],
    ]);
  }
  await _learnMerchantCategoryImpl(
    repo,
    merchantTitle: candidate.title,
    category: learnedCategory,
  );
  await _upsertPaybillAndFulizaImpl(repo, candidate);
  await _logAuditImpl(
    repo,
    sourceHash: candidate.sourceHash,
    semanticHash: candidate.semanticHash,
    route: candidate.route.name,
    confidence: candidate.confidenceScore,
    decision: 'imported',
    status: 'done',
    payload: _auditPayloadForCandidate(candidate),
  );
}

Future<void> _insertReviewImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
  await repo._store.executor.runInsert(
    'INSERT OR IGNORE INTO sms_review_queue('
    'scope, source_hash, semantic_hash, title, category, amount, occurred_at, raw_message, confidence, status, created_at'
    ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'local',
      candidate.sourceHash,
      candidate.semanticHash,
      candidate.title,
      candidate.category,
      candidate.amountKes,
      candidate.occurredAt.millisecondsSinceEpoch,
      candidate.rawMessage,
      candidate.confidenceScore,
      'pending',
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
  await _logAuditImpl(
    repo,
    sourceHash: candidate.sourceHash,
    semanticHash: candidate.semanticHash,
    route: candidate.route.name,
    confidence: candidate.confidenceScore,
    decision: 'review_pending',
    status: 'done',
    payload: _auditPayloadForCandidate(candidate),
  );
}

Future<void> _insertQuarantineImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
  await repo._store.executor.runInsert(
    'INSERT OR IGNORE INTO sms_quarantine('
    'scope, source_hash, semantic_hash, raw_message, reason, confidence, status, created_at,'
    'title, category, amount, occurred_at'
    ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'local',
      candidate.sourceHash,
      candidate.semanticHash,
      candidate.rawMessage,
      candidate.reason ?? 'Low confidence classification',
      candidate.confidenceScore,
      'pending',
      DateTime.now().millisecondsSinceEpoch,
      candidate.title,
      candidate.category,
      candidate.amountKes,
      candidate.occurredAt.millisecondsSinceEpoch,
    ],
  );
  await _logAuditImpl(
    repo,
    sourceHash: candidate.sourceHash,
    semanticHash: candidate.semanticHash,
    route: candidate.route.name,
    confidence: candidate.confidenceScore,
    decision: 'quarantined',
    status: 'done',
    payload: _auditPayloadForCandidate(candidate),
  );
}

Future<void> _upsertPaybillAndFulizaImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate, {
  bool reconcile = true,
}) async {
  if (candidate.paybillAccount != null &&
      candidate.paybillAccount!.isNotEmpty) {
    await repo._store.executor.runInsert(
      'INSERT INTO paybill_registry(paybill, display_name, last_seen_at, usage_count) '
      'VALUES (?, ?, ?, 1) '
      'ON CONFLICT(paybill) DO UPDATE SET '
      'display_name = excluded.display_name, '
      'last_seen_at = excluded.last_seen_at, '
      'usage_count = paybill_registry.usage_count + 1',
      [
        candidate.paybillAccount!,
        candidate.title,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }
  final isFuliza =
      candidate.transactionType == MpesaTransactionType.fulizaDraw ||
      candidate.transactionType == MpesaTransactionType.fulizaRepayment ||
      candidate.transactionType == MpesaTransactionType.fulizaCharge;
  if (!isFuliza) {
    return;
  }
  await repo._store.executor.runInsert(
    'INSERT OR IGNORE INTO fuliza_lifecycle_events('
    'scope, mpesa_code, event_kind, amount, occurred_at, raw_message, source_hash'
    ') VALUES (?, ?, ?, ?, ?, ?, ?)',
    [
      'local',
      candidate.mpesaCode,
      candidate.transactionType.name,
      candidate.amountKes,
      candidate.occurredAt.millisecondsSinceEpoch,
      candidate.rawMessage,
      candidate.sourceHash,
    ],
  );
  // Reconcile draw↔repayment pairs after any Fuliza event is recorded. Runs
  // regardless of which row was inserted first, so ordering within a batch
  // does not matter. Callers may pass reconcile: false and call
  // _reconcileFulizaLinksImpl once per chunk for better throughput.
  if (reconcile) await _reconcileFulizaLinksImpl(repo);
}

/// Pairs each still-unlinked Fuliza repayment with the most recent unlinked
/// draw that occurred at or before it — the debt being paid down. Real
/// repayments are frequently partial or bundle the access fee, so amounts are
/// deliberately NOT required to match. Idempotent: only touches unlinked rows.
Future<void> _reconcileFulizaLinksImpl(ExpensesRepositoryImpl repo) async {
  final repayments = await repo._store.executor.runSelect(
    'SELECT id, mpesa_code, occurred_at FROM fuliza_lifecycle_events '
    'WHERE scope = ? AND event_kind = ? AND linked_code IS NULL '
    'ORDER BY occurred_at',
    ['local', MpesaTransactionType.fulizaRepayment.name],
  );
  for (final rep in repayments) {
    final repId = rep['id'] as int;
    final repCode = rep['mpesa_code'] as String;
    final repTime = rep['occurred_at'] as int;
    final draws = await repo._store.executor.runSelect(
      'SELECT id, mpesa_code FROM fuliza_lifecycle_events '
      'WHERE scope = ? AND event_kind = ? AND linked_code IS NULL '
      'AND occurred_at <= ? '
      'ORDER BY occurred_at DESC LIMIT 1',
      ['local', MpesaTransactionType.fulizaDraw.name, repTime],
    );
    if (draws.isEmpty) continue;
    final drawId = draws.first['id'] as int;
    final drawCode = draws.first['mpesa_code'] as String;
    // Cross-link both rows: draw ← repayment code, repayment ← draw code.
    await repo._store.executor.runUpdate(
      'UPDATE fuliza_lifecycle_events SET linked_code = ? WHERE id = ?',
      [repCode, drawId],
    );
    await repo._store.executor.runUpdate(
      'UPDATE fuliza_lifecycle_events SET linked_code = ? WHERE id = ?',
      [drawCode, repId],
    );
  }
}

bool _shouldCreateIncome(ParsedMpesaCandidate candidate) {
  if (candidate.amountKes <= 0) return false;
  if (candidate.transactionType == MpesaTransactionType.received ||
      candidate.transactionType == MpesaTransactionType.deposit) {
    return true;
  }
  if (candidate.category.toLowerCase() == 'income') return true;
  final titleLower = candidate.title.toLowerCase();
  final incomeKeywords = const [
    'salary',
    'dividend',
    'refund',
    'bonus',
    'commission',
    'interest',
  ];
  return incomeKeywords.any(titleLower.contains);
}

Future<void> _insertIncomeBatchImpl(
  ExpensesRepositoryImpl repo,
  List<List<Object?>> batch,
) async {
  await repo._store.ensureInitialized();
  for (final row in batch) {
    final title = '${row[0]}';
    final amount = (row[1] as num).toDouble();
    final receivedAt = (row[2] as num).toInt();
    final sourceHash = row.length > 4 ? row[4] as String? : null;
    // Primary dedup: source_hash (exact match) when available.
    if (sourceHash != null && sourceHash.isNotEmpty) {
      final existing = await repo._store.executor.runSelect(
        'SELECT id FROM incomes WHERE source_hash = ? LIMIT 1',
        [sourceHash],
      );
      if (existing.isNotEmpty) continue;
    } else {
      // Fallback: fuzzy match on amount + timestamp for legacy rows without hash.
      final existing = await repo._store.executor.runSelect(
        'SELECT id FROM incomes '
        'WHERE source = ? AND ABS(amount - ?) <= 0.01 AND received_at = ? LIMIT 1',
        ['sms', amount, receivedAt],
      );
      if (existing.isNotEmpty) continue;
    }
    await repo._store.executor.runInsert(
      'INSERT INTO incomes(title, amount, received_at, source, source_hash) VALUES (?, ?, ?, ?, ?)',
      [title, amount, receivedAt, 'sms', sourceHash],
    );
  }
}
