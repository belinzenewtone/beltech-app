import 'package:beltech/data/local/drift/app_drift_store.dart';

class IntegrityReport {
  final bool isHealthy;
  final List<IntegrityCheck> checks;
  final DateTime checkedAt;
  const IntegrityReport({
    required this.isHealthy,
    required this.checks,
    required this.checkedAt,
  });
}

class IntegrityCheck {
  final String name;
  final bool passed;
  final String message;
  const IntegrityCheck({
    required this.name,
    required this.passed,
    required this.message,
  });
}

class DataIntegrityService {
  DataIntegrityService(this._store);

  final AppDriftStore _store;

  Future<IntegrityReport> runChecks() async {
    await _store.ensureInitialized();
    final checks = <IntegrityCheck>[];
    final now = DateTime.now();

    checks.add(await _checkNoNegativeAmounts());
    checks.add(await _checkNoFutureTransactions());
    checks.add(await _checkValidCategories());
    checks.add(await _checkSourceHashUniqueness());
    checks.add(await _checkOrphanedTasks());
    checks.add(await _checkValidDateRanges());
    checks.add(await _checkRowCounts());

    final isHealthy = checks.every((c) => c.passed);
    return IntegrityReport(
      isHealthy: isHealthy,
      checks: checks,
      checkedAt: now,
    );
  }

  int _readCount(List<Map<String, Object?>> rows) =>
      rows.isEmpty ? 0 : (rows.first['cnt'] as int);

  Future<IntegrityCheck> _checkNoNegativeAmounts() async {
    final rows = await _store.executor.runSelect(
      'SELECT COUNT(*) as cnt FROM transactions WHERE amount < 0',
      const [],
    );
    final count = _readCount(rows);
    return IntegrityCheck(
      name: 'No negative amounts',
      passed: count == 0,
      message: count == 0
          ? 'All amounts are non-negative'
          : 'Found $count transaction(s) with negative amounts',
    );
  }

  Future<IntegrityCheck> _checkNoFutureTransactions() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now + 86400000;
    final rows = await _store.executor.runSelect(
      'SELECT COUNT(*) as cnt FROM transactions WHERE occurred_at > ?',
      [cutoff],
    );
    final count = _readCount(rows);
    return IntegrityCheck(
      name: 'No future-dated transactions',
      passed: count == 0,
      message: count == 0
          ? 'All transactions have valid dates'
          : 'Found $count transaction(s) with future dates',
    );
  }

  Future<IntegrityCheck> _checkValidCategories() async {
    final rows = await _store.executor.runSelect(
      "SELECT COUNT(*) as cnt FROM transactions WHERE category IS NULL OR trim(category) = ''",
      const [],
    );
    final count = _readCount(rows);
    return IntegrityCheck(
      name: 'Valid categories',
      passed: count == 0,
      message: count == 0
          ? 'All transactions have categories'
          : 'Found $count transaction(s) with empty categories',
    );
  }

  Future<IntegrityCheck> _checkSourceHashUniqueness() async {
    final rows = await _store.executor.runSelect(
      'SELECT COUNT(*) as cnt FROM (SELECT source_hash, COUNT(*) as c '
      'FROM transactions WHERE source_hash IS NOT NULL '
      'GROUP BY source_hash HAVING c > 1)',
      const [],
    );
    final count = _readCount(rows);
    return IntegrityCheck(
      name: 'No duplicate source hashes',
      passed: count == 0,
      message: count == 0
          ? 'No duplicate transactions'
          : 'Found $count duplicate source hash(es)',
    );
  }

  Future<IntegrityCheck> _checkOrphanedTasks() async {
    final rows = await _store.executor.runSelect(
      "SELECT COUNT(*) as cnt FROM tasks WHERE title IS NULL OR trim(title) = ''",
      const [],
    );
    final count = _readCount(rows);
    return IntegrityCheck(
      name: 'No orphaned tasks',
      passed: count == 0,
      message: count == 0
          ? 'All tasks have titles'
          : 'Found $count task(s) with empty titles',
    );
  }

  Future<IntegrityCheck> _checkValidDateRanges() async {
    final rows = await _store.executor.runSelect(
      'SELECT COUNT(*) as cnt FROM events WHERE end_at IS NOT NULL AND end_at < start_at',
      const [],
    );
    final count = _readCount(rows);
    return IntegrityCheck(
      name: 'Valid event date ranges',
      passed: count == 0,
      message: count == 0
          ? 'All event dates are valid'
          : 'Found $count event(s) with end before start',
    );
  }

  Future<IntegrityCheck> _checkRowCounts() async {
    final txRows = await _store.executor.runSelect(
      'SELECT COUNT(*) as cnt FROM transactions',
      const [],
    );
    final taskRows = await _store.executor.runSelect(
      'SELECT COUNT(*) as cnt FROM tasks',
      const [],
    );
    final txCount = _readCount(txRows);
    final taskCount = _readCount(taskRows);
    final total = txCount + taskCount;
    return IntegrityCheck(
      name: 'Row count sanity',
      passed: true,
      message:
          'Database has $txCount transactions and $taskCount tasks ($total total records)',
    );
  }
}
