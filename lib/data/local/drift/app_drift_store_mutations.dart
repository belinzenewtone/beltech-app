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
    emitChange();
  }

  Future<void> deleteTransaction(int id) async {
    await ensureInitialized();
    await executor.runDelete('DELETE FROM transactions WHERE id = ?', [id]);
    emitChange();
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

/// SMS ingest queue state machine — atomic status transitions for WorkManager
/// crash-safety and per-item retry accounting.
extension AppDriftStoreSmsQueue on AppDriftStore {
  /// Atomically claim up to [limit] PENDING/RETRY rows by setting them to
  /// PROCESSING so a crashed worker doesn't re-pick the same rows.
  Future<List<Map<String, Object?>>> claimPendingQueue({int limit = 100}) async {
    await ensureInitialized();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final rows = await executor.runSelect(
      'SELECT id, raw_message, attempt, source_timestamp '
      'FROM sms_import_queue '
      'WHERE scope = ? AND status IN (?, ?) AND (next_retry_at IS NULL OR next_retry_at <= ?) '
      'ORDER BY created_at ASC LIMIT ?',
      ['local', 'pending', 'retry', nowMs, limit],
    );
    if (rows.isEmpty) return rows;
    final ids = rows.map((r) => r['id']!).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    await executor.runUpdate(
      'UPDATE sms_import_queue SET status = ?, updated_at = ? WHERE id IN ($placeholders)',
      ['processing', nowMs, ...ids],
    );
    return rows;
  }

  Future<void> markQueueRowDone(int id) async {
    await ensureInitialized();
    await executor.runUpdate(
      'UPDATE sms_import_queue SET status = ?, updated_at = ? WHERE id = ?',
      ['done', DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  /// Mark a row as failed with exponential back-off up to a max of 3 attempts.
  /// On the 3rd failure the row is permanently marked failed.
  Future<void> markQueueRowFailed(
    int id, {
    required String reason,
    required int attempt,
  }) async {
    await ensureInitialized();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nextAttempt = attempt + 1;
    if (nextAttempt >= 3) {
      await executor.runUpdate(
        'UPDATE sms_import_queue SET status = ?, updated_at = ?, last_error = ? WHERE id = ?',
        ['failed', nowMs, reason, id],
      );
      return;
    }
    final retryDelayMs = (1 << nextAttempt.clamp(0, 5)) * 60 * 1000;
    await executor.runUpdate(
      'UPDATE sms_import_queue SET status = ?, attempt = ?, next_retry_at = ?, updated_at = ?, last_error = ? WHERE id = ?',
      ['retry', nextAttempt, nowMs + retryDelayMs, nowMs, reason, id],
    );
  }

  /// Reset rows that were left in PROCESSING (by a crashed worker) back to
  /// PENDING so they can be re-picked on the next run.  Called at the start of
  /// every [SmsIngestionWorker] invocation.
  Future<int> resetStaleProcessingRows() async {
    await ensureInitialized();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = nowMs - 5 * 60 * 1000; // 5 min stale threshold
    return executor.runUpdate(
      'UPDATE sms_import_queue SET status = ?, updated_at = ? '
      'WHERE scope = ? AND status = ? AND updated_at < ?',
      ['pending', nowMs, 'local', 'processing', cutoffMs],
    );
  }

  /// Reset retry/failed rows back to pending for re-processing.
  /// Used after a fresh enqueue of already-queued messages.
  Future<void> retryQueueRows(List<String> sourceHashes) async {
    await ensureInitialized();
    if (sourceHashes.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final hash in sourceHashes) {
      await executor.runUpdate(
        "UPDATE sms_import_queue SET "
        "status = CASE WHEN status IN ('retry', 'failed') THEN 'pending' ELSE status END, "
        "attempt = CASE WHEN status IN ('retry', 'failed') THEN 0 ELSE attempt END, "
        "next_retry_at = CASE WHEN status IN ('retry', 'failed') THEN NULL ELSE next_retry_at END, "
        "last_error = CASE WHEN status IN ('retry', 'failed') THEN NULL ELSE last_error END, "
        "updated_at = ? "
        'WHERE scope = ? AND source_hash = ?',
        [nowMs, 'local', hash],
      );
    }
  }
}
