import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/tasks/domain/entities/task_time_entry.dart';
import 'package:beltech/features/tasks/domain/repositories/time_tracking_repository.dart';

class TimeTrackingRepositoryImpl implements TimeTrackingRepository {
  TimeTrackingRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Future<List<TaskTimeEntry>> fetchEntries(int taskId) async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, task_id, started_at, ended_at, duration_sec, note '
      'FROM task_time_entries WHERE task_id = ? ORDER BY started_at DESC',
      [taskId],
    );
    return rows.map(_rowToEntry).toList();
  }

  @override
  Future<TaskTimeEntry?> activeEntry(int taskId) async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, task_id, started_at, ended_at, duration_sec, note '
      'FROM task_time_entries WHERE task_id = ? AND ended_at IS NULL '
      'ORDER BY started_at DESC LIMIT 1',
      [taskId],
    );
    if (rows.isEmpty) return null;
    return _rowToEntry(rows.first);
  }

  @override
  Future<void> startTimer(int taskId) async {
    await _store.ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _store.executor.runInsert(
      'INSERT INTO task_time_entries(task_id, started_at) VALUES (?, ?)',
      [taskId, now],
    );
    _store.emitChange();
  }

  @override
  Future<void> stopTimer(int entryId) async {
    await _store.ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await _store.executor.runSelect(
      'SELECT started_at FROM task_time_entries WHERE id = ?',
      [entryId],
    );
    if (rows.isEmpty) return;
    final startedAt = _asInt(rows.first['started_at']);
    final durationSec = ((now - startedAt) / 1000).round();
    await _store.executor.runUpdate(
      'UPDATE task_time_entries SET ended_at = ?, duration_sec = ? WHERE id = ?',
      [now, durationSec, entryId],
    );
    _store.emitChange();
  }

  @override
  Future<void> deleteEntry(int entryId) async {
    await _store.ensureInitialized();
    await _store.executor.runDelete(
      'DELETE FROM task_time_entries WHERE id = ?',
      [entryId],
    );
    _store.emitChange();
  }

  @override
  Future<int> totalTrackedSeconds(int taskId) async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT COALESCE(SUM(duration_sec), 0) AS total '
      'FROM task_time_entries WHERE task_id = ?',
      [taskId],
    );
    final completed = _asInt(rows.firstOrNull?['total']);

    final active = await activeEntry(taskId);
    if (active != null && active.startedAt != null) {
      final elapsedMs =
          DateTime.now().millisecondsSinceEpoch -
          active.startedAt!.millisecondsSinceEpoch;
      return completed + (elapsedMs / 1000).round();
    }

    return completed;
  }

  TaskTimeEntry _rowToEntry(Map<String, Object?> row) {
    return TaskTimeEntry(
      id: _asInt(row['id']),
      taskId: _asInt(row['task_id']),
      startedAt: row['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_asInt(row['started_at']))
          : null,
      endedAt: row['ended_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_asInt(row['ended_at']))
          : null,
      durationSec: row['duration_sec'] != null ? _asInt(row['duration_sec']) : null,
      note: row['note'] as String?,
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
