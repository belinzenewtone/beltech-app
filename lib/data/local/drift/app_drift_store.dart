import 'dart:async';

import 'package:beltech/data/local/drift/app_drift_records.dart';
import 'package:beltech/data/local/drift/drift_executor_factory.dart';
import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show OpeningDetails;

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
    await _AppDriftSchema.seedDataIfEmpty(this);
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
  ) =>
      _watch(() => _loadEventsInRange(start, end));
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
  }) async {
    await _ensureInitialized();
    final timestamp = (occurredAt ?? DateTime.now()).millisecondsSinceEpoch;
    await _db.runInsert(
      'INSERT INTO transactions(title, category, amount, occurred_at, source, source_hash, transaction_type, balance_after) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        title,
        category,
        amountKes,
        timestamp,
        source,
        sourceHash,
        transactionType,
        balanceAfterKes,
      ],
    );
    _emitChange();
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  }) async {
    await _ensureInitialized();
    await _db.runInsert(
      'INSERT INTO tasks(title, description, completed, due_at, priority, reminder_enabled, reminder_minutes_before) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        title,
        description,
        0,
        dueDate?.millisecondsSinceEpoch,
        priority,
        reminderEnabled ? 1 : 0,
        reminderMinutesBefore,
      ],
    );
    _emitChange();
  }

  Future<void> toggleTaskCompletion({
    required int taskId,
    required bool completed,
  }) async {
    await _ensureInitialized();
    await _db.runUpdate('UPDATE tasks SET completed = ? WHERE id = ?', [
      completed ? 1 : 0,
      taskId,
    ]);
    _emitChange();
  }

  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    String priority = 'medium',
    String eventType = 'general',
    DateTime? endAt,
    String? note,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 15,
  }) async {
    await _ensureInitialized();
    await _db.runInsert(
      'INSERT INTO events(title, start_at, end_at, note, completed, priority, event_type, reminder_enabled, reminder_minutes_before) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        title,
        startAt.millisecondsSinceEpoch,
        endAt?.millisecondsSinceEpoch,
        note,
        0,
        priority,
        eventType,
        reminderEnabled ? 1 : 0,
        reminderMinutesBefore,
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
  ) =>
      _AppDriftQueries.loadEventsInRange(this, start, end);

  Future<List<DriftEventRecord>> _loadAllEvents() =>
      _AppDriftQueries.loadAllEvents(this);

  Future<int> _countRows(String tableName) =>
      _AppDriftQueries.countRows(this, tableName);

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
