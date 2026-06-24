import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/budget/domain/entities/budget_target.dart';
import 'package:beltech/features/budget/domain/entities/budget_target_progress.dart';

class BuildBudgetTargetProgressesUseCase {
  const BuildBudgetTargetProgressesUseCase();

  List<BudgetTargetProgress> call({
    required List<BudgetTarget> targets,
    required BudgetSnapshot snapshot,
  }) {
    final spentByCategory = <String, double>{
      for (final item in snapshot.items)
        item.category.trim().toLowerCase(): item.spentKes,
    };

    final rows = targets
        .map(
          (target) => BudgetTargetProgress(
            id: target.id,
            category: target.category,
            monthlyLimitKes: target.monthlyLimitKes,
            spentKes:
                spentByCategory[target.category.trim().toLowerCase()] ?? 0,
          ),
        )
        .toList();

    rows.sort((left, right) {
      final usageCompare = right.usageRatio.compareTo(left.usageRatio);
      if (usageCompare != 0) {
        return usageCompare;
      }
      return right.spentKes.compareTo(left.spentKes);
    });
    return rows;
  }
}
