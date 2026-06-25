import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/income/domain/usecases/build_income_overview_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildIncomeOverviewUseCase();

  test('builds totals, month cashflow, and six-month trend', () {
    final overview = useCase(
      incomes: [
        IncomeItem(
          id: 1,
          title: 'Salary',
          amountKes: 5000,
          receivedAt: DateTime(2026, 1, 5),
          source: 'manual',
        ),
        IncomeItem(
          id: 2,
          title: 'Project',
          amountKes: 1500,
          receivedAt: DateTime(2026, 2, 9),
          source: 'manual',
        ),
        IncomeItem(
          id: 3,
          title: 'Freelance',
          amountKes: 1800,
          receivedAt: DateTime(2026, 3, 11),
          source: 'manual',
        ),
        IncomeItem(
          id: 4,
          title: 'Bonus',
          amountKes: 700,
          receivedAt: DateTime(2026, 4, 2),
          source: 'manual',
        ),
        IncomeItem(
          id: 5,
          title: 'Commission',
          amountKes: 2100,
          receivedAt: DateTime(2026, 5, 17),
          source: 'manual',
        ),
        IncomeItem(
          id: 6,
          title: 'Payout',
          amountKes: 1300,
          receivedAt: DateTime(2026, 6, 8),
          source: 'manual',
        ),
        IncomeItem(
          id: 7,
          title: 'Allowance',
          amountKes: 900,
          receivedAt: DateTime(2026, 7, 1),
          source: 'manual',
        ),
      ],
      expenseTransactions: [
        ExpenseItem(
          id: 1,
          title: 'Food',
          category: 'Food',
          amountKes: 400,
          occurredAt: DateTime(2026, 7, 3),
        ),
        ExpenseItem(
          id: 2,
          title: 'Fuel',
          category: 'Transport',
          amountKes: 250,
          occurredAt: DateTime(2026, 7, 10),
        ),
        ExpenseItem(
          id: 3,
          title: 'Old',
          category: 'Bills',
          amountKes: 100,
          occurredAt: DateTime(2026, 6, 12),
        ),
      ],
      now: DateTime(2026, 7, 20),
    );

    expect(overview.totalIncomeKes, 13300);
    expect(overview.currentMonthIncomeKes, 900);
    expect(overview.currentMonthExpenseKes, 650);
    expect(overview.netCashflowKes, 250);
    expect(overview.trend.map((point) => point.label), [
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
    ]);
    expect(overview.trend.last.incomeKes, 900);
  });
}
