import 'package:beltech/data/local/drift/app_drift_store.dart';

extension AppDriftStoreMutations on AppDriftStore {
  Future<void> updateTransaction({
    required int id,
    required String title,
    required String category,
    required double amountKes,
    required DateTime occurredAt,
  }) async {
    await ensureInitialized();
    final before = await _transactionRollupFields(id);
    await executor.runUpdate(
      'UPDATE transactions SET title = ?, category = ?, amount = ?, occurred_at = ?, source = ?, source_hash = NULL, transaction_type = ?, balance_after = NULL WHERE id = ?',
      [
        title,
        category,
        amountKes,
        occurredAt.millisecondsSinceEpoch,
        'manual',
        'expense',
        id,
      ],
    );
    // Reverse the old contribution, add the new one. Only when the row existed
    // — a no-op UPDATE (unknown id) must not inject a phantom +1.
    if (before != null) {
      await applyRollupDelta(
        category: before.category,
        amount: before.amount,
        occurredAtMs: before.occurredAtMs,
        sign: -1,
      );
      await applyRollupDelta(
        category: category,
        amount: amountKes,
        occurredAtMs: occurredAt.millisecondsSinceEpoch,
        sign: 1,
      );
    }
    emitChange();
  }

  Future<void> deleteTransaction(int id) async {
    await ensureInitialized();
    final before = await _transactionRollupFields(id);
    await executor.runDelete('DELETE FROM transactions WHERE id = ?', [id]);
    if (before != null) {
      await applyRollupDelta(
        category: before.category,
        amount: before.amount,
        occurredAtMs: before.occurredAtMs,
        sign: -1,
      );
    }
    emitChange();
  }

  /// Reads the rollup-relevant fields of a transaction before it is mutated,
  /// so the change can be reversed out of the aggregates.
  Future<({String category, double amount, int occurredAtMs})?>
  _transactionRollupFields(int id) async {
    final rows = await executor.runSelect(
      'SELECT category, amount, occurred_at FROM transactions WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return (
      category: (r['category'] ?? 'Other') as String,
      amount: (r['amount'] as num?)?.toDouble() ?? 0,
      occurredAtMs: (r['occurred_at'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> updateTask({
    required int id,
    required String title,
    String? description,
    required DateTime? deadline,
    required String priority,
    required String status,
    int? completedAt,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
  }) async {
    await ensureInitialized();
    await executor.runUpdate(
      'UPDATE tasks SET title = ?, description = ?, deadline = ?, priority = ?, status = ?, completed_at = ?, reminder_offsets = ?, alarm_enabled = ? WHERE id = ?',
      [
        title,
        description,
        deadline?.millisecondsSinceEpoch,
        priority,
        status,
        completedAt,
        reminderOffsets.join(','),
        alarmEnabled ? 1 : 0,
        id,
      ],
    );
    emitChange();
  }

  Future<void> deleteTask(int id) async {
    await ensureInitialized();
    await executor.runDelete('DELETE FROM tasks WHERE id = ?', [id]);
    emitChange();
  }

  Future<void> updateEvent({
    required int id,
    required String title,
    required DateTime startAt,
    required String priority,
    required String eventType,
    required String eventKind,
    required DateTime? endAt,
    String? note,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
    bool allDay = false,
    String repeatRule = 'never',
    String guests = '',
    String timeZoneId = '',
    int reminderTimeOfDayMinutes = 480,
  }) async {
    await ensureInitialized();
    await executor.runUpdate(
      'UPDATE events SET title = ?, start_at = ?, end_at = ?, note = ?, priority = ?, event_type = ?, event_kind = ?, all_day = ?, repeat_rule = ?, reminder_offsets = ?, alarm_enabled = ?, guests = ?, time_zone_id = ?, reminder_time_of_day_minutes = ? WHERE id = ?',
      [
        title,
        startAt.millisecondsSinceEpoch,
        endAt?.millisecondsSinceEpoch,
        note,
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
        id,
      ],
    );
    emitChange();
  }

  Future<void> deleteEvent(int id) async {
    await ensureInitialized();
    await executor.runDelete('DELETE FROM events WHERE id = ?', [id]);
    emitChange();
  }
}
