import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/learning/domain/entities/learning_session.dart';
import 'package:beltech/features/learning/domain/repositories/learning_repository.dart';

class LearningRepositoryImpl implements LearningRepository {
  LearningRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<LearningSession>> watchSessions() async* {
    yield await loadSessions();
    await for (final _ in _store.watchChangeStream()) {
      yield await loadSessions();
    }
  }

  @override
  Future<List<LearningSession>> loadSessions() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, topic, duration_minutes, date FROM learning_sessions ORDER BY date DESC',
      const [],
    );
    return rows.map(_rowToSession).toList();
  }

  @override
  Future<void> addSession({
    required String topic,
    required int durationMinutes,
    required DateTime date,
  }) async {
    await _store.ensureInitialized();
    await _store.executor.runInsert(
      'INSERT INTO learning_sessions(topic, duration_minutes, date) VALUES (?, ?, ?)',
      [topic, durationMinutes, date.millisecondsSinceEpoch],
    );
    _store.emitChange();
  }

  @override
  Future<void> deleteSession(int id) async {
    await _store.ensureInitialized();
    await _store.executor.runDelete(
      'DELETE FROM learning_sessions WHERE id = ?',
      [id],
    );
    _store.emitChange();
  }

  @override
  Future<int> currentStreak() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT DISTINCT date / 86400000 AS day FROM learning_sessions ORDER BY day DESC',
      const [],
    );
    if (rows.isEmpty) return 0;
    final days = rows.map((r) => _asInt(r['day'])).toList();
    final today = DateTime.now().millisecondsSinceEpoch ~/ 86400000;
    if (days.first < today - 1) return 0;
    int streak = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i] == days[i - 1] - 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Future<int> monthlyMinutes(DateTime month) async {
    await _store.ensureInitialized();
    final start = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final end = DateTime(month.year, month.month + 1, 1).millisecondsSinceEpoch;
    final rows = await _store.executor.runSelect(
      'SELECT COALESCE(SUM(duration_minutes), 0) AS total FROM learning_sessions WHERE date >= ? AND date < ?',
      [start, end],
    );
    return _asInt(rows.firstOrNull?['total']);
  }

  LearningSession _rowToSession(Map<String, Object?> row) {
    return LearningSession(
      id: _asInt(row['id']),
      topic: '${row['topic'] ?? ''}',
      durationMinutes: _asInt(row['duration_minutes']),
      date: DateTime.fromMillisecondsSinceEpoch(_asInt(row['date'])),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
