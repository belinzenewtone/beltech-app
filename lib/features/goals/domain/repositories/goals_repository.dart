import 'package:beltech/features/goals/domain/entities/goal_item.dart';

abstract interface class GoalsRepository {
  Stream<List<GoalItem>> watchGoals();
  Future<List<GoalItem>> loadGoals();
  Future<void> addGoal({
    required String title,
    required double targetAmount,
    double currentAmount,
    DateTime? deadline,
    String? color,
  });
  Future<void> updateGoal({
    required int id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? color,
  });
  Future<void> deleteGoal(int id);
}
