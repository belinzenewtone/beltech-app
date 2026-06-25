import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/budget/domain/entities/budget_target.dart';
import 'package:beltech/features/budget/domain/usecases/build_budget_target_progresses_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildBudgetTargetProgressesUseCase();

  test('maps targets to spent progress and sorts highest pressure first', () {
    final rows = useCase(
      targets: const [
        BudgetTarget(id: 1, category: 'Food', monthlyLimitKes: 1000),
        BudgetTarget(id: 2, category: 'Transport', monthlyLimitKes: 1000),
        BudgetTarget(id: 3, category: 'Rent', monthlyLimitKes: 5000),
      ],
      snapshot: BudgetSnapshot(
        month: DateTime(2026, 3, 1),
        items: const [
          BudgetCategoryItem(
            category: 'Food',
            monthlyLimitKes: 1000,
            spentKes: 900,
          ),
          BudgetCategoryItem(
            category: 'Transport',
            monthlyLimitKes: 1000,
            spentKes: 1200,
          ),
        ],
      ),
    );

    expect(rows.map((item) => item.category), ['Transport', 'Food', 'Rent']);
    expect(rows.first.isOverLimit, isTrue);
    expect(rows.first.remainingKes, -200);
    expect(rows[1].isNearLimit, isTrue);
    expect(rows[1].remainingKes, 100);
    expect(rows.last.spentKes, 0);
  });
}
