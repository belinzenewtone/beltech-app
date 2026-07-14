import 'dart:async';

import 'package:beltech/data/local/drift/app_drift_records.dart';
import 'package:beltech/data/local/drift/drift_executor_factory.dart';
import 'package:drift/backends.dart';
import 'package:drift/drift.dart'
    show ArgumentsForBatchedStatement, BatchedStatements, OpeningDetails;

part 'app_drift_store_queries.dart';
part 'app_drift_store_schema.dart';
part 'app_drift_store_schema_migrations.dart';
part 'app_drift_store_utils.dart';

class AppDriftStore {
  AppDriftStore()
    : _db = openDriftExecutor(name: 'dart_2_0_app.sqlite', inMemory: true);

  AppDriftStore.persistent()
    : _db = openDriftExecutor(name: 'dart_2_0_app.sqlite');

  final QueryExecutor _db;
  final StreamController<int> _changes = StreamController<int>.broadcast();

  bool _initialized = false;
  Future<void>? _initFuture;
  int _changeSeq = 0;

  QueryExecutor get executor => _db;

  Future<void> ensureInitialized() => _ensureInitialized();

  void emitChange() => _emitChange();

  Future<void> resetAllData() async {
    await _ensureInitialized();
    const tables = [
      'transactions',
      'tasks',
      'events',
      'incomes',
      'budgets',
      'recurring_templates',
      'sms_import_queue',
      'sms_import_audit',
      'sms_review_queue',
      'sms_quarantine',
      'paybill_registry',
      'merchant_categories',
      'fuliza_lifecycle_events',
      'bills',
      'loans',
      'goals',
      'learning_sessions',
      'app_updates',
    ];
    for (final table in tables) {
      await _db.runDelete('DELETE FROM $table', const []);
    }
    _emitChange();
  }

  Future<void> dispose() async {
    await _changes.close();
    await _db.close();
  }

  Stream<HomeOverviewRecord> watchHomeOverview() => _watch(_loadHomeOverview);

  Stream<ExpensesSnapshotRecord> watchExpensesSnapshot() =>
      _watch(_loadExpensesSnapshot);

  Stream<List<DriftTaskRecord>> watchTasks() => _watch(_loadTasks);

  Stream<int> watchChangeStream() => _changes.stream;

  Stream<List<DriftEventRecord>> watchEventsForDay(DateTime day) =>
      _watch(() => _loadEventsForDay(day));
  Stream<List<DriftEventRecord>> watchEventsInRange(
    DateTime start,
    DateTime end,
  ) => _watch(() => _loadEventsInRange(start, end));
  Stream<List<DriftEventRecord>> watchAllEvents() => _watch(_loadAllEvents);

  Future<void> addTransaction({
    required String title,
    required String category,
    required double amountKes,
    DateTime? occurredAt,
    String source = 'manual',
    String? sourceHash,
    String transactionType = 'expense',
    double? balanceAfterKes,
    String? mpesaCode,
  }) async {
    await _ensureInitialized();
    final timestamp = (occurredAt ?? DateTime.now()).millisecondsSinceEpoch;
    final code = (mpesaCode == null || mpesaCode.isEmpty) ? null : mpesaCode;
    await _db.runInsert(
      'INSERT INTO transactions(title, category, amount, occurred_at, source, source_hash, transaction_type, balance_after, mpesa_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [title, category, amountKes, timestamp, source, sourceHash, transactionType, balanceAfterKes, code],
    );
    _emitChange();
  }

  /// Efficiently insert many transaction rows in a single batched statement.
  /// Each row must have 9 elements: title, category, amount, occurred_at,
  /// source, source_hash, transaction_type, balance_after, mpesa_code.
  /// Callers must emit their own change event(s).
  Future<void> addTransactionsBatch(List<List<Object?>> rows) async {
    await _ensureInitialized();
    if (rows.isEmpty) return;
    await _db.runBatched(
      BatchedStatements(
        const [
          'INSERT INTO transactions(title, category, amount, occurred_at, source, source_hash, transaction_type, balance_after, mpesa_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ],
        rows.map((r) => ArgumentsForBatchedStatement(0, r)).toList(),
      ),
    );
  }

  Future<void> insertSmsReviewBatch(List<List<Object?>> rows) async {
    await _ensureInitialized();
    if (rows.isEmpty) return;
    await _db.runBatched(
      BatchedStatements(
        const [
          'INSERT OR IGNORE INTO sms_review_queue('
          'scope, source_hash, semantic_hash, title, category, amount, occurred_at, raw_message, confidence, status, created_at'
          ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ],
        rows.map((r) => ArgumentsForBatchedStatement(0, r)).toList(),
      ),
    );
  }

  Future<void> insertSmsQuarantineBatch(List<List<Object?>> rows) async {
    await _ensureInitialized();
    if (rows.isEmpty) return;
    await _db.runBatched(
      BatchedStatements(
        const [
          'INSERT OR IGNORE INTO sms_quarantine('
          'scope, source_hash, semantic_hash, raw_message, reason, confidence, status, created_at'
          ') VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        ],
        rows.map((r) => ArgumentsForBatchedStatement(0, r)).toList(),
      ),
    );
  }

  Future<void> insertSmsImportAuditBatch(List<List<Object?>> rows) async {
    await _ensureInitialized();
    if (rows.isEmpty) return;
    await _db.runBatched(
      BatchedStatements(
        const [
          'INSERT INTO sms_import_audit('
          'scope, source_hash, semantic_hash, route, confidence, decision, status, payload, created_at'
          ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ],
        rows.map((r) => ArgumentsForBatchedStatement(0, r)).toList(),
      ),
    );
  }

  Future<void> updateSmsImportQueueStatusBatch(List<List<Object?>> rows) async {
    await _ensureInitialized();
    if (rows.isEmpty) return;
    await _db.runBatched(
      BatchedStatements(
        const [
          'UPDATE sms_import_queue SET status = ?, updated_at = ?, last_error = ? WHERE id = ?',
        ],
        rows.map((r) => ArgumentsForBatchedStatement(0, r)).toList(),
      ),
    );
  }

  Future<void> insertSmsImportQueueBatch(List<List<Object?>> rows) async {
    await _ensureInitialized();
    if (rows.isEmpty) return;
    await _db.runBatched(
      BatchedStatements(
        const [
          'INSERT OR IGNORE INTO sms_import_queue('
          'scope, raw_message, source_hash, semantic_hash, source_timestamp, status, route, confidence, created_at, updated_at'
          ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ],
        rows.map((r) => ArgumentsForBatchedStatement(0, r)).toList(),
      ),
    );
  }

  /// Refreshes an existing queue row with the latest parse metadata and resets
  /// retry/failed status so the message will be reprocessed.
  Future<void> refreshSmsImportQueueBatch(List<List<Object?>> rows) async {
    await _ensureInitialized();
    if (rows.isEmpty) return;
    await _db.runBatched(
      BatchedStatements(
        const [
          'UPDATE sms_import_queue SET '
          'raw_message = ?, '
          'semantic_hash = ?, '
          'source_timestamp = CASE '
          '  WHEN ? IS NULL THEN source_timestamp '
          '  WHEN source_timestamp IS NULL OR ? > source_timestamp THEN ? '
          '  ELSE source_timestamp '
          'END, '
          'route = ?, '
          'confidence = ?, '
          'status = CASE WHEN status IN (?, ?) THEN ? ELSE status END, '
          'attempt = CASE WHEN status IN (?, ?) THEN 0 ELSE attempt END, '
          'next_retry_at = CASE WHEN status IN (?, ?) THEN NULL ELSE next_retry_at END, '
          'last_error = CASE WHEN status IN (?, ?) THEN NULL ELSE last_error END, '
          'updated_at = ? '
          'WHERE scope = ? AND source_hash = ?',
        ],
        rows.map((r) => ArgumentsForBatchedStatement(0, r)).toList(),
      ),
    );
  }

  Future<int> addTask({
    required String title,
    String? description,
    DateTime? deadline,
    String priority = 'neutral',
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
  }) async {
    await _ensureInitialized();
    final id = await _db.runInsert(
      'INSERT INTO tasks(title, description, status, priority, deadline, reminder_offsets, alarm_enabled, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        title,
        description,
        'pending',
        priority,
        deadline?.millisecondsSinceEpoch,
        reminderOffsets.join(','),
        alarmEnabled ? 1 : 0,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    _emitChange();
    return id;
  }

  Future<void> setTaskCompletion({
    required int taskId,
    required bool completed,
  }) async {
    await _ensureInitialized();
    if (completed) {
      await _db.runUpdate(
        "UPDATE tasks SET status = 'completed', completed_at = ? WHERE id = ?",
        [DateTime.now().millisecondsSinceEpoch, taskId],
      );
    } else {
      await _db.runUpdate(
        "UPDATE tasks SET status = 'pending', completed_at = NULL WHERE id = ?",
        [taskId],
      );
    }
    _emitChange();
  }

  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    String priority = 'neutral',
    String eventType = 'personal',
    String eventKind = 'event',
    DateTime? endAt,
    String? note,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
    bool allDay = false,
    String repeatRule = 'never',
    String guests = '',
    String timeZoneId = '',
    int reminderTimeOfDayMinutes = 480,
  }) async {
    await _ensureInitialized();
    await _db.runInsert(
      'INSERT INTO events(title, start_at, end_at, note, completed, priority, event_type, event_kind, all_day, repeat_rule, reminder_offsets, alarm_enabled, guests, time_zone_id, reminder_time_of_day_minutes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        title,
        startAt.millisecondsSinceEpoch,
        endAt?.millisecondsSinceEpoch,
        note,
        0,
        priority,
        eventType,
        eventKind,
        allDay ? 1 : 0,
        repeatRule,
        reminderOffsets.join(','),
        alarmEnabled ? 1 : 0,
        guests,
        timeZoneId,
        reminderTimeOfDayMinutes,
      ],
    );
    _emitChange();
  }

  Future<void> setEventCompletion({
    required int eventId,
    required bool completed,
  }) async {
    await _ensureInitialized();
    await _db.runUpdate('UPDATE events SET completed = ? WHERE id = ?', [
      completed ? 1 : 0,
      eventId,
    ]);
    _emitChange();
  }

  Stream<T> _watch<T>(Future<T> Function() loader) {
    return Stream<T>.multi((controller) async {
      await _ensureInitialized();
      Future<void> publishSnapshot() async {
        if (!controller.isClosed) {
          controller.add(await loader());
        }
      }

      final subscription = _changes.stream.listen(
        (_) async => publishSnapshot(),
        onError: controller.addError,
      );
      await publishSnapshot();
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> _ensureInitialized() {
    if (_initialized) return Future.value();
    return _initFuture ??= _AppDriftSchema.ensureInitialized(this);
  }

  Future<HomeOverviewRecord> _loadHomeOverview() =>
      _AppDriftQueries.loadHomeOverview(this);

  Future<ExpensesSnapshotRecord> _loadExpensesSnapshot() =>
      _AppDriftQueries.loadExpensesSnapshot(this);

  Future<List<DriftTaskRecord>> _loadTasks() =>
      _AppDriftQueries.loadTasks(this);

  Future<List<DriftEventRecord>> _loadEventsForDay(DateTime day) =>
      _AppDriftQueries.loadEventsForDay(this, day);

  Future<List<DriftEventRecord>> _loadEventsInRange(
    DateTime start,
    DateTime end,
  ) => _AppDriftQueries.loadEventsInRange(this, start, end);

  Future<List<DriftEventRecord>> _loadAllEvents() =>
      _AppDriftQueries.loadAllEvents(this);

  Future<int> _countRows(String tableName) =>
      _AppDriftQueries.countRows(this, tableName);

  Future<int> countRows(String tableName) => _countRows(tableName);

  void _emitChange() => _AppDriftUtils.emitChange(this);

  int _asInt(Object? value) => _AppDriftUtils.asInt(value);

  double _asDouble(Object? value) => _AppDriftUtils.asDouble(value);
}

class _StoreQueryExecutorUser implements QueryExecutorUser {
  const _StoreQueryExecutorUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
