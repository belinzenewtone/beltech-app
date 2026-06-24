import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/goals/domain/entities/goal_item.dart';
import 'package:beltech/features/goals/domain/repositories/goals_repository.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  GoalsRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<GoalItem>> watchGoals() {
    return _store.watchChangeStream().asyncMap((_) => loadGoals());
  }

  @override
  Future<List<GoalItem>> loadGoals() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, title, target_amount, current_amount, deadline, color, created_at FROM goals ORDER BY created_at DESC',
      const [],
    );
    return rows.map(_rowToGoal).toList();
  }

  @override
  Future<void> addGoal({
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    String? color,
  }) async {
    await _store.ensureInitialized();
    await _store.executor.runInsert(
      'INSERT INTO goals(title, target_amount, current_amount, deadline, color, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        title, targetAmount, currentAmount,
        deadline?.millisecondsSinceEpoch, color,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    _store.emitChange();
  }

  @override
  Future<void> updateGoal({
    required int id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? color,
  }) async {
    await _store.ensureInitialized();
    final sets = <String>[];
    final args = <Object?>[];
    if (title != null) { sets.add('title = ?'); args.add(title); }
    if (targetAmount != null) { sets.add('target_amount = ?'); args.add(targetAmount); }
    if (currentAmount != null) { sets.add('current_amount = ?'); args.add(currentAmount); }
    if (deadline != null) { sets.add('deadline = ?'); args.add(deadline.millisecondsSinceEpoch); }
    if (color != null) { sets.add('color = ?'); args.add(color); }
    if (sets.isEmpty) return;
    args.add(id);
    await _store.executor.runUpdate('UPDATE goals SET ${sets.join(', ')} WHERE id = ?', args);
    _store.emitChange();
  }

  @override
  Future<void> deleteGoal(int id) async {
    await _store.ensureInitialized();
    await _store.executor.runDelete('DELETE FROM goals WHERE id = ?', [id]);
    _store.emitChange();
  }

  GoalItem _rowToGoal(Map<String, Object?> row) {
    return GoalItem(
      id: _asInt(row['id']),
      title: '${row['title'] ?? ''}',
      targetAmount: _asDouble(row['target_amount']),
      currentAmount: _asDouble(row['current_amount']),
      deadline: row['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_asInt(row['deadline']))
          : null,
      color: row['color'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_asInt(row['created_at'])),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
