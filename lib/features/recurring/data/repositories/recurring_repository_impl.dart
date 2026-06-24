import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';
import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<RecurringTemplate>> watchTemplates() {
    return _store.watchExpensesSnapshot().asyncMap((_) => _loadTemplates());
  }

  @override
  Future<void> addTemplate({
    required RecurringKind kind,
    required String title,
    String? description,
    String? category,
    double? amountKes,
    String? priority,
    required RecurringCadence cadence,
    required DateTime nextRunAt,
    bool enabled = true,
  }) async {
    await _store.ensureInitialized();
    await _store.executor.runInsert(
      'INSERT INTO recurring_templates(kind, title, description, category, amount, priority, cadence, next_run_at, enabled) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        kind.name,
        title,
        description,
        category,
        amountKes,
        priority,
        cadence.name,
        nextRunAt.millisecondsSinceEpoch,
        enabled ? 1 : 0,
      ],
    );
    _store.emitChange();
  }

  @override
  Future<void> updateTemplate({
    required int templateId,
    required RecurringKind kind,
    required String title,
    String? description,
    String? category,
    double? amountKes,
    String? priority,
    required RecurringCadence cadence,
    required DateTime nextRunAt,
    required bool enabled,
  }) async {
    await _store.ensureInitialized();
    await _store.executor.runUpdate(
      'UPDATE recurring_templates '
      'SET kind = ?, title = ?, description = ?, category = ?, amount = ?, priority = ?, cadence = ?, next_run_at = ?, enabled = ? '
      'WHERE id = ?',
      [
        kind.name,
        title,
        description,
        category,
        amountKes,
        priority,
        cadence.name,
        nextRunAt.millisecondsSinceEpoch,
        enabled ? 1 : 0,
        templateId,
      ],
    );
    _store.emitChange();
  }

  @override
  Future<void> deleteTemplate(int templateId) async {
    await _store.ensureInitialized();
    await _store.executor.runDelete(
        'DELETE FROM recurring_templates WHERE id = ?', [templateId]);
    _store.emitChange();
  }

  @override
  Future<int> materializeDue({DateTime? now}) async {
    await _store.ensureInitialized();
    final clock = now ?? DateTime.now();
    final dueRows = await _store.executor.runSelect(
      'SELECT id, kind, title, description, category, amount, priority, cadence, next_run_at '
      'FROM recurring_templates '
      'WHERE enabled = 1 AND next_run_at <= ? '
      'ORDER BY next_run_at ASC',
      [clock.millisecondsSinceEpoch],
    );
    if (dueRows.isEmpty) {
      return 0;
    }
    var inserted = 0;
    for (final row in dueRows) {
      final kind = _kindFrom('${row['kind'] ?? ''}');
      final when =
          DateTime.fromMillisecondsSinceEpoch(_asInt(row['next_run_at']));
      final title = '${row['title'] ?? ''}';
      final description = row['description'] as String?;
      final category = row['category'] as String?;
      final amount = _asDouble(row['amount']);
      final priority = '${row['priority'] ?? 'medium'}';

      switch (kind) {
        case RecurringKind.expense:
          await _store.executor.runInsert(
            'INSERT INTO transactions(title, category, amount, occurred_at, source, source_hash) '
            'VALUES (?, ?, ?, ?, ?, ?)',
            [
              title,
              category ?? 'Other',
              amount,
              when.millisecondsSinceEpoch,
              'recurring',
              null,
            ],
          );
          inserted += 1;
        case RecurringKind.income:
          await _store.executor.runInsert(
            'INSERT INTO incomes(title, amount, received_at, source) VALUES (?, ?, ?, ?)',
            [title, amount, when.millisecondsSinceEpoch, 'recurring'],
          );
          inserted += 1;
        case RecurringKind.task:
          await _store.executor.runInsert(
            'INSERT INTO tasks(title, description, completed, due_at, priority) VALUES (?, ?, ?, ?, ?)',
            [title, description, 0, when.millisecondsSinceEpoch, priority],
          );
          inserted += 1;
        case RecurringKind.event:
          await _store.executor.runInsert(
            'INSERT INTO events(title, start_at, end_at, note) VALUES (?, ?, ?, ?)',
            [title, when.millisecondsSinceEpoch, null, description],
          );
          inserted += 1;
      }

      final cadence = _cadenceFrom('${row['cadence'] ?? ''}');
      final nextRun = _nextRun(when, cadence);
      await _store.executor.runUpdate(
        'UPDATE recurring_templates SET next_run_at = ? WHERE id = ?',
        [nextRun.millisecondsSinceEpoch, _asInt(row['id'])],
      );
    }
    _store.emitChange();
    return inserted;
  }

  Future<List<RecurringTemplate>> _loadTemplates() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, kind, title, description, category, amount, priority, cadence, next_run_at, enabled '
      'FROM recurring_templates ORDER BY next_run_at ASC, id DESC',
      const [],
    );
    return rows
        .map(
          (row) => RecurringTemplate(
            id: _asInt(row['id']),
            kind: _kindFrom('${row['kind'] ?? ''}'),
            title: '${row['title'] ?? ''}',
            description: row['description'] as String?,
            category: row['category'] as String?,
            amountKes: row['amount'] == null ? null : _asDouble(row['amount']),
            priority: row['priority'] as String?,
            cadence: _cadenceFrom('${row['cadence'] ?? ''}'),
            nextRunAt:
                DateTime.fromMillisecondsSinceEpoch(_asInt(row['next_run_at'])),
            enabled: _asInt(row['enabled']) == 1,
          ),
        )
        .toList();
  }

  DateTime _nextRun(DateTime from, RecurringCadence cadence) {
    return switch (cadence) {
      RecurringCadence.daily => from.add(const Duration(days: 1)),
      RecurringCadence.weekly => from.add(const Duration(days: 7)),
      RecurringCadence.monthly => DateTime(
          from.year,
          from.month + 1,
          from.day,
          from.hour,
          from.minute,
        ),
    };
  }

  RecurringKind _kindFrom(String raw) {
    return switch (raw.toLowerCase()) {
      'income' => RecurringKind.income,
      'task' => RecurringKind.task,
      'event' => RecurringKind.event,
      _ => RecurringKind.expense,
    };
  }

  RecurringCadence _cadenceFrom(String raw) {
    return switch (raw.toLowerCase()) {
      'weekly' => RecurringCadence.weekly,
      'monthly' => RecurringCadence.monthly,
      _ => RecurringCadence.daily,
    };
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }
}
