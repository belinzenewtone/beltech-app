part of 'expenses_repository_impl.dart';

Future<ExpenseImportMetrics> _fetchImportMetricsImpl(
  ExpensesRepositoryImpl repo,
) async {
  await repo._store.ensureInitialized();
  final review = await repo._count(
    'sms_review_queue',
    where: 'scope = ? AND status = ?',
    params: ['local', 'pending'],
  );
  final quarantine = await repo._count(
    'sms_quarantine',
    where: 'scope = ? AND status = ?',
    params: ['local', 'pending'],
  );
  final retry = await repo._count(
    'sms_import_queue',
    where: 'scope = ? AND status = ?',
    params: ['local', 'retry'],
  );
  final failed = await repo._count(
    'sms_import_queue',
    where: 'scope = ? AND status = ?',
    params: ['local', 'failed'],
  );
  final latestRows = await repo._store.executor.runSelect(
    'SELECT raw_message, last_error, updated_at, status '
    'FROM sms_import_queue '
    'WHERE scope = ? '
    'ORDER BY updated_at DESC LIMIT 1',
    ['local'],
  );

  DateTime? lastImportAt;
  String? lastMpesaCode;
  String? lastError;
  if (latestRows.isNotEmpty) {
    final row = latestRows.first;
    final updatedAt = repo._asInt(row['updated_at']);
    lastImportAt = DateTime.fromMillisecondsSinceEpoch(updatedAt);
    lastError = row['last_error'] as String?;
    lastError = lastError?.trim().isEmpty ?? true ? null : lastError;
    final rawMessage = '${row['raw_message'] ?? ''}';
    lastMpesaCode = MpesaParserService.extractMpesaCode(rawMessage);
  }

  final quarantineReasonBreakdown = await _fetchQuarantineBreakdown(repo);
  final duplicateSkipCount = await _fetchDuplicateSkipCount(repo);
  final dailyTrends = await _fetchDailyImportTrends(repo);
  final alerts = _generateImportAlerts(
    review: review,
    quarantine: quarantine,
    retry: retry,
    failed: failed,
    breakdown: quarantineReasonBreakdown,
    duplicateSkipCount: duplicateSkipCount,
    dailyTrends: dailyTrends,
  );

  return ExpenseImportMetrics(
    reviewQueueCount: review,
    quarantineCount: quarantine,
    retryQueueCount: retry,
    failedQueueCount: failed,
    lastImportAt: lastImportAt,
    lastMpesaCode: lastMpesaCode,
    lastError: lastError,
    quarantineReasonBreakdown: quarantineReasonBreakdown,
    duplicateSkipCount: duplicateSkipCount,
    dailyTrends: dailyTrends,
    alerts: alerts,
  );
}

Future<Map<String, int>> _fetchQuarantineBreakdown(
  ExpensesRepositoryImpl repo,
) async {
  final rows = await repo._store.executor.runSelect(
    'SELECT reason, COUNT(*) AS c '
    'FROM sms_quarantine '
    'WHERE scope = ? AND status = ? '
    'GROUP BY reason',
    ['local', 'pending'],
  );
  final result = <String, int>{};
  for (final row in rows) {
    final reason = '${row['reason'] ?? 'Unknown'}'.trim();
    result[reason.isEmpty ? 'Unknown' : reason] = repo._asInt(row['c']);
  }
  return result;
}

Future<int> _fetchDuplicateSkipCount(ExpensesRepositoryImpl repo) async {
  final rows = await repo._store.executor.runSelect(
    "SELECT COUNT(*) AS c FROM sms_import_audit WHERE scope = ? AND decision = ?",
    ['local', 'duplicate'],
  );
  if (rows.isEmpty) return 0;
  return repo._asInt(rows.first['c']);
}

Future<List<DailyImportTrend>> _fetchDailyImportTrends(
  ExpensesRepositoryImpl repo,
) async {
  final since = DateTime.now()
      .subtract(const Duration(days: 30))
      .millisecondsSinceEpoch;
  final rows = await repo._store.executor.runSelect(
    "SELECT date(created_at/1000, 'unixepoch') AS day, "
    "COUNT(*) AS total, "
    "SUM(CASE WHEN decision = ? THEN 1 ELSE 0 END) AS quarantine, "
    "AVG(confidence) AS avg_conf "
    "FROM sms_import_audit "
    "WHERE scope = ? AND created_at >= ? "
    "GROUP BY day "
    "ORDER BY day DESC "
    "LIMIT ?",
    ['quarantined', 'local', since, 30],
  );
  return rows.map((row) {
    final dayStr = '${row['day'] ?? ''}';
    final parsedDate = DateTime.tryParse(dayStr) ?? DateTime.now();
    return DailyImportTrend(
      date: parsedDate,
      total: repo._asInt(row['total']),
      quarantineCount: repo._asInt(row['quarantine']),
      averageConfidence: repo._asDouble(row['avg_conf']),
    );
  }).toList(growable: false);
}

List<String> _generateImportAlerts({
  required int review,
  required int quarantine,
  required int retry,
  required int failed,
  required Map<String, int> breakdown,
  required int duplicateSkipCount,
  required List<DailyImportTrend> dailyTrends,
}) {
  final alerts = <String>[];
  final totalIssues = review + quarantine + retry + failed;
  final totalItems = totalIssues + duplicateSkipCount;

  if (totalItems > 0 && quarantine / totalItems > 0.3) {
    alerts.add(
      'Warning: ${(quarantine / totalItems * 100).toStringAsFixed(0)}% of recent imports are quarantined.',
    );
  }

  final missingAmount = breakdown['Missing amount'] ?? 0;
  if (missingAmount > 5) {
    alerts.add(
      'Parser issue suspected: $missingAmount messages have a valid code but no amount.',
    );
  }

  if (dailyTrends.length >= 2) {
    final latestUnknown = dailyTrends.first.quarantineCount;
    final previousUnknown = dailyTrends[1].quarantineCount;
    if (previousUnknown > 0 && latestUnknown > previousUnknown * 2) {
      alerts.add(
        'Sudden spike in unknown/low-confidence messages ($previousUnknown → $latestUnknown).',
      );
    }
  }

  if (duplicateSkipCount > 0) {
    alerts.add(
      '$duplicateSkipCount duplicate message${duplicateSkipCount == 1 ? '' : 's'} skipped.',
    );
  }

  return alerts;
}

Future<List<ExpenseReviewItem>> _fetchReviewQueueImpl(
  ExpensesRepositoryImpl repo, {
  int limit = 20,
}) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT id, title, category, amount, occurred_at, confidence, raw_message '
    'FROM sms_review_queue WHERE scope = ? AND status = ? '
    'ORDER BY created_at DESC LIMIT ?',
    ['local', 'pending', limit],
  );
  return rows
      .map(
        (row) => ExpenseReviewItem(
          id: repo._asInt(row['id']),
          title: '${row['title'] ?? ''}',
          category: '${row['category'] ?? 'Other'}',
          amountKes: repo._asDouble(row['amount']),
          occurredAt: DateTime.fromMillisecondsSinceEpoch(
            repo._asInt(row['occurred_at']),
          ),
          confidence: repo._asDouble(row['confidence']),
          rawMessage: '${row['raw_message'] ?? ''}',
        ),
      )
      .toList();
}

Future<List<ExpenseQuarantineItem>> _fetchQuarantineItemsImpl(
  ExpensesRepositoryImpl repo, {
  int limit = 20,
}) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT id, reason, confidence, raw_message, created_at '
    'FROM sms_quarantine WHERE scope = ? AND status = ? '
    'ORDER BY created_at DESC LIMIT ?',
    ['local', 'pending', limit],
  );
  return rows
      .map(
        (row) => ExpenseQuarantineItem(
          id: repo._asInt(row['id']),
          reason: '${row['reason'] ?? 'Unknown reason'}',
          confidence: repo._asDouble(row['confidence']),
          rawMessage: '${row['raw_message'] ?? ''}',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            repo._asInt(row['created_at']),
          ),
        ),
      )
      .toList();
}

Future<void> _resolveReviewItemImpl(
  ExpensesRepositoryImpl repo, {
  required int reviewId,
  required bool approve,
}) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT source_hash, semantic_hash, title, category, amount, occurred_at, confidence '
    'FROM sms_review_queue WHERE id = ? AND status = ? LIMIT 1',
    [reviewId, 'pending'],
  );
  if (rows.isEmpty) {
    return;
  }
  final row = rows.first;
  final occurredAt = DateTime.fromMillisecondsSinceEpoch(
    repo._asInt(row['occurred_at']),
  );
  final title = '${row['title'] ?? 'MPESA Transaction'}';
  final category = '${row['category'] ?? 'Other'}';
  if (approve) {
    final learned = await _resolveLearnedCategoryImpl(
      repo,
      merchantTitle: title,
      fallbackCategory: category,
      amountKes: repo._asDouble(row['amount']),
    );
    await repo._store.addTransaction(
      title: title,
      category: learned,
      amountKes: repo._asDouble(row['amount']),
      occurredAt: occurredAt,
      source: 'sms_review',
      sourceHash: '${row['source_hash'] ?? ''}',
    );
    await _learnMerchantCategoryImpl(
      repo,
      merchantTitle: title,
      category: learned,
    );
  }
  await repo._store.executor.runUpdate(
    'UPDATE sms_review_queue SET status = ?, resolved_at = ? WHERE id = ?',
    ['resolved', DateTime.now().millisecondsSinceEpoch, reviewId],
  );
  await _logAuditImpl(
    repo,
    sourceHash: '${row['source_hash'] ?? ''}',
    semanticHash: '${row['semantic_hash'] ?? ''}',
    route: MpesaParseRoute.reviewQueue.name,
    confidence: repo._asDouble(row['confidence']),
    decision: approve ? 'review_approved' : 'review_rejected',
    status: 'done',
    payload: _auditPayloadForAction(origin: 'review_queue'),
  );
  repo._store.emitChange();
}

Future<void> _dismissQuarantineItemImpl(
  ExpensesRepositoryImpl repo,
  int quarantineId,
) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT source_hash, semantic_hash, confidence '
    'FROM sms_quarantine WHERE id = ? AND status = ? LIMIT 1',
    [quarantineId, 'pending'],
  );
  if (rows.isEmpty) {
    return;
  }
  final row = rows.first;
  await repo._store.executor.runUpdate(
    'UPDATE sms_quarantine SET status = ? WHERE id = ?',
    ['dismissed', quarantineId],
  );
  await _logAuditImpl(
    repo,
    sourceHash: '${row['source_hash'] ?? ''}',
    semanticHash: '${row['semantic_hash'] ?? ''}',
    route: MpesaParseRoute.quarantine.name,
    confidence: repo._asDouble(row['confidence']),
    decision: 'quarantine_dismissed',
    status: 'done',
    payload: _auditPayloadForAction(origin: 'quarantine'),
  );
  repo._store.emitChange();
}

Future<void> _approveQuarantineItemImpl(
  ExpensesRepositoryImpl repo,
  int quarantineId,
) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT source_hash, semantic_hash, title, category, amount, occurred_at, confidence '
    'FROM sms_quarantine WHERE id = ? AND status = ? LIMIT 1',
    [quarantineId, 'pending'],
  );
  if (rows.isEmpty) {
    return;
  }
  final row = rows.first;
  final occurredAt = DateTime.fromMillisecondsSinceEpoch(
    repo._asInt(row['occurred_at']),
  );
  final title = '${row['title'] ?? 'MPESA Transaction'}';
  final category = '${row['category'] ?? 'Other'}';

  // Add transaction
  await repo._store.addTransaction(
    title: title,
    category: category,
    amountKes: repo._asDouble(row['amount']),
    occurredAt: occurredAt,
    source: 'quarantine_approved',
    sourceHash: '${row['source_hash'] ?? ''}',
  );

  // Update quarantine status
  await repo._store.executor.runUpdate(
    'UPDATE sms_quarantine SET status = ? WHERE id = ?',
    ['approved', quarantineId],
  );

  // Log audit
  await _logAuditImpl(
    repo,
    sourceHash: '${row['source_hash'] ?? ''}',
    semanticHash: '${row['semantic_hash'] ?? ''}',
    route: MpesaParseRoute.quarantine.name,
    confidence: repo._asDouble(row['confidence']),
    decision: 'quarantine_approved',
    status: 'done',
    payload: _auditPayloadForAction(origin: 'quarantine'),
  );

  repo._store.emitChange();
}

Future<void> _rejectQuarantineItemImpl(
  ExpensesRepositoryImpl repo,
  int quarantineId,
) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT source_hash, semantic_hash, confidence '
    'FROM sms_quarantine WHERE id = ? AND status = ? LIMIT 1',
    [quarantineId, 'pending'],
  );
  if (rows.isEmpty) {
    return;
  }
  final row = rows.first;

  // Update quarantine status to rejected
  await repo._store.executor.runUpdate(
    'UPDATE sms_quarantine SET status = ? WHERE id = ?',
    ['rejected', quarantineId],
  );

  // Log audit
  await _logAuditImpl(
    repo,
    sourceHash: '${row['source_hash'] ?? ''}',
    semanticHash: '${row['semantic_hash'] ?? ''}',
    route: MpesaParseRoute.quarantine.name,
    confidence: repo._asDouble(row['confidence']),
    decision: 'quarantine_rejected',
    status: 'done',
    payload: _auditPayloadForAction(origin: 'quarantine'),
  );

  repo._store.emitChange();
}

Future<void> _updateAndApproveQuarantineItemImpl(
  ExpensesRepositoryImpl repo, {
  required int quarantineId,
  required String title,
  required double amountKes,
  String? category,
}) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT source_hash, semantic_hash, occurred_at, confidence '
    'FROM sms_quarantine WHERE id = ? AND status = ? LIMIT 1',
    [quarantineId, 'pending'],
  );
  if (rows.isEmpty) {
    return;
  }
  final row = rows.first;
  final occurredAt = DateTime.fromMillisecondsSinceEpoch(
    repo._asInt(row['occurred_at']),
  );
  final finalCategory = category ?? 'Other';

  // Add transaction with edited values
  await repo._store.addTransaction(
    title: title,
    category: finalCategory,
    amountKes: amountKes,
    occurredAt: occurredAt,
    source: 'quarantine_edited_approved',
    sourceHash: '${row['source_hash'] ?? ''}',
  );

  // Update quarantine status
  await repo._store.executor.runUpdate(
    'UPDATE sms_quarantine SET status = ? WHERE id = ?',
    ['approved_with_edits', quarantineId],
  );

  // Log audit
  await _logAuditImpl(
    repo,
    sourceHash: '${row['source_hash'] ?? ''}',
    semanticHash: '${row['semantic_hash'] ?? ''}',
    route: MpesaParseRoute.quarantine.name,
    confidence: repo._asDouble(row['confidence']),
    decision: 'quarantine_approved_edited',
    status: 'done',
    payload: _auditPayloadForAction(origin: 'quarantine'),
  );

  repo._store.emitChange();
}

Future<bool> _isDuplicateImpl(
  ExpensesRepositoryImpl repo,
  ParsedMpesaCandidate candidate,
) async {
  // Tier 1: M-Pesa transaction code is the strongest dedup signal.
  if (candidate.mpesaCode.isNotEmpty) {
    final codeRows = await repo._store.executor.runSelect(
      'SELECT id FROM transactions WHERE mpesa_code = ? LIMIT 1',
      [candidate.mpesaCode],
    );
    if (codeRows.isNotEmpty) return true;
  }
  // Tier 2: source hash (SHA-256 of raw SMS text).
  final sourceRows = await repo._store.executor.runSelect(
    'SELECT id FROM transactions WHERE source_hash = ? LIMIT 1',
    [candidate.sourceHash],
  );
  if (sourceRows.isNotEmpty) return true;
  // Tier 3: semantic hash via the audit log — catches rephrased duplicates.
  final semanticRows = await repo._store.executor.runSelect(
    'SELECT id FROM sms_import_audit '
    'WHERE scope = ? AND semantic_hash = ? AND decision IN (?, ?, ?) LIMIT 1',
    ['local', candidate.semanticHash, 'imported', 'duplicate', 'review_pending'],
  );
  if (semanticRows.isNotEmpty) return true;
  // Tier 4: 5-minute heuristic — same merchant + same amount within a 5-min
  // window catches retried/double-sent transactions with different codes.
  final windowMs = 5 * 60 * 1000;
  final windowStart = candidate.occurredAt.millisecondsSinceEpoch - windowMs;
  final windowEnd = candidate.occurredAt.millisecondsSinceEpoch + windowMs;
  final heuristicRows = await repo._store.executor.runSelect(
    'SELECT id FROM transactions '
    'WHERE occurred_at >= ? AND occurred_at <= ? '
    'AND ABS(amount - ?) <= 1.0 AND LOWER(title) = ? '
    'LIMIT 1',
    [windowStart, windowEnd, candidate.amountKes, candidate.title.toLowerCase()],
  );
  return heuristicRows.isNotEmpty;
}

Future<void> _markDoneImpl(
  ExpensesRepositoryImpl repo,
  int queueId, {
  required String status,
  String? lastError,
}) async {
  await repo._store.executor.runUpdate(
    'UPDATE sms_import_queue SET status = ?, updated_at = ?, last_error = ? WHERE id = ?',
    [status, DateTime.now().millisecondsSinceEpoch, lastError, queueId],
  );
}

Future<void> _logAuditImpl(
  ExpensesRepositoryImpl repo, {
  required String sourceHash,
  required String semanticHash,
  required String route,
  required double confidence,
  required String decision,
  required String status,
  required Map<String, Object?> payload,
}) async {
  await repo._store.executor.runInsert(
    'INSERT INTO sms_import_audit('
    'scope, source_hash, semantic_hash, route, confidence, decision, status, payload, created_at'
    ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'local',
      sourceHash,
      semanticHash,
      route,
      confidence,
      decision,
      status,
      jsonEncode(payload),
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
}

Map<String, Object?> _auditPayloadForCandidate(ParsedMpesaCandidate candidate) {
  return {
    'channel': 'sms_import_v2',
    'transaction_family': candidate.transactionType.name,
    'amount_band': _amountBand(candidate.amountKes),
    'has_paybill': candidate.paybillAccount?.isNotEmpty == true,
    'has_fuliza':
        candidate.transactionType == MpesaTransactionType.fulizaDraw ||
        candidate.transactionType == MpesaTransactionType.fulizaRepayment ||
        candidate.transactionType == MpesaTransactionType.fulizaCharge,
  };
}

Map<String, Object?> _auditPayloadForAction({required String origin}) {
  return {'channel': 'sms_import_v2', 'origin': origin};
}

String _amountBand(double amountKes) {
  if (amountKes < 100) {
    return 'lt_100';
  }
  if (amountKes < 1000) {
    return 'lt_1000';
  }
  if (amountKes < 10000) {
    return 'lt_10000';
  }
  return 'gte_10000';
}
