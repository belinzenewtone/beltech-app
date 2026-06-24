import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/goals/data/repositories/goals_repository_impl.dart';
import 'package:beltech/features/goals/domain/entities/goal_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late GoalsRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = GoalsRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('addGoal and loadGoals persist correctly', () async {
    await repository.addGoal(
      title: 'Emergency Fund',
      targetAmount: 50000,
      currentAmount: 15000,
      deadline: DateTime(2024, 12, 31),
    );

    final goals = await repository.loadGoals();
    expect(goals.length, 1);
    expect(goals.first.title, 'Emergency Fund');
    expect(goals.first.targetAmount, 50000);
    expect(goals.first.currentAmount, 15000);
    expect(goals.first.progressPercent, 0.3);
  });

  test('updateGoal and deleteGoal work correctly', () async {
    await repository.addGoal(
      title: 'Vacation',
      targetAmount: 20000,
      currentAmount: 5000,
    );

    final created = await repository.loadGoals();
    final goal = created.first;

    await repository.updateGoal(id: goal.id, currentAmount: 10000);
    final updated = await repository.loadGoals();
    expect(updated.first.currentAmount, 10000);
    expect(updated.first.progressPercent, 0.5);

    await repository.deleteGoal(goal.id);
    final afterDelete = await repository.loadGoals();
    expect(afterDelete, isEmpty);
  });

  test('isAtRisk detects behind-schedule goals', () async {
    final goal = GoalItem(
      id: 1,
      title: 'Test',
      targetAmount: 1000,
      currentAmount: 100,
      deadline: DateTime.now().add(const Duration(days: 10)),
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    );
    expect(goal.isAtRisk, true);
  });
}
