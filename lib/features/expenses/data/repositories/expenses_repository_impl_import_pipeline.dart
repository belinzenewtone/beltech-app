part of 'expenses_repository_impl.dart';

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
}) async {
  final now = DateTime.now();
  final rows = await repo._store.executor.runSelect(
    'SELECT id, raw_message, attempt, source_timestamp '
    'FROM sms_import_queue '
    'WHERE scope = ? AND status IN (?, ?) AND (next_retry_at IS NULL OR next_retry_at <= ?) '
    'ORDER BY created_at ASC LIMIT 400',
    ['local', 'pending', 'retry', now.millisecondsSinceEpoch],
  );
  if (rows.isEmpty) {
    return 0;
  }

  var imported = 0;
  for (var i = 0; i < rows.length; i += _queueProcessChunkSize) {
    final chunk = rows.sublist(
      i,
      (i + _queueProcessChunkSize).clamp(0, rows.length),
    );
    try {
      imported += await _processQueueChunk(repo, chunk, from: from);
    } catch (error) {
      // If a batch fails (e.g. constraint violation in one row), fall back to
      // the original one-by-one path so retries and per-row failures work.
      imported += await _processQueueChunkRowByRow(repo, chunk, from: from);
    }
  }
  repo._store.emitChange();
  return imported;
}

Future<int> _processQueueChunk(
  ExpensesRepositoryImpl repo,
  List<Map<String, Object?>> rows, {
  DateTime? from,
}) async {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final jobs = rows.map((row) {
    final raw = '${row['raw_message'] ?? ''}';
    final sourceTimestampRaw = row['source_timestamp'];
    final fallback = sourceTimestampRaw == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            repo._asInt(sourceTimestampRaw),
          );
    return SmsParseJob(raw, fallbackOccurredAt: fallback);
  }).toList(growable: false);

  final candidates = await MpesaParserService.parseJobsInIsolate(jobs);
  final candidateByQueueId = <int, ParsedMpesaCandidate>{};
  for (var i = 0; i < candidates.length && i < rows.length; i++) {
    final queueId = repo._asInt(rows[i]['id']);
    candidateByQueueId[queueId] = candidates[i];
  }

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

      if (await _isDuplicateImpl(repo, candidate) ||
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
  for (final direct in directRows) {
    final queueId = direct.queueId;
    final candidate = direct.candidate;
    try {
      if (candidate.transactionType == MpesaTransactionType.fulizaCharge) {
        await _upsertPaybillAndFulizaImpl(repo, candidate);
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
      await _upsertPaybillAndFulizaImpl(repo, candidate);
      transactionBatch.add([
        candidate.title,
        learnedCategory,
        candidate.amountKes,
        candidate.occurredAt.millisecondsSinceEpoch,
        'sms',
        candidate.sourceHash,
        candidate.transactionType.name,
        candidate.balanceAfterKes,
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

  try {
    if (transactionBatch.isNotEmpty) {
      await repo._store.addTransactionsBatch(transactionBatch);
    }
    if (incomeBatch.isNotEmpty) {
      await _insertIncomeBatchImpl(repo, incomeBatch);
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
  } catch (error) {
    // DB-level batch failure: fall back to row-by-row so each row can retry
    // or fail individually without losing the whole chunk.
    return _processQueueChunkRowByRow(repo, rows, from: from);
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
    'scope, source_hash, semantic_hash, raw_message, reason, confidence, status, created_at'
    ') VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'local',
      candidate.sourceHash,
      candidate.semanticHash,
      candidate.rawMessage,
      candidate.reason ?? 'Low confidence classification',
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
    decision: 'quarantined',
    status: 'done',
    payload: _auditPayloadForCandidate(candidate),
  );
}

Future<void> _upsertPaybillAndFulizaImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
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
    final existing = await repo._store.executor.runSelect(
      'SELECT id FROM incomes '
      'WHERE source = ? AND ABS(amount - ?) <= 0.01 AND received_at = ? LIMIT 1',
      ['sms', amount, receivedAt],
    );
    if (existing.isNotEmpty) continue;
    await repo._store.executor.runInsert(
      'INSERT INTO incomes(title, amount, received_at, source) VALUES (?, ?, ?, ?)',
      [title, amount, receivedAt, 'sms'],
    );
  }
}
