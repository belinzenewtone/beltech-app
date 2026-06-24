import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_data_use_case.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildWeekReviewDataUseCase();

  test('builds weekly review totals from finance and task signals', () {
    final data = useCase(
      expenses: ExpensesSnapshot(
        todayKes: 0,
        weekKes: 0,
        categories: const [],
        transactions: [
          ExpenseItem(
            id: 1,
            title: 'Food',
            category: 'Food',
            amountKes: 500,
            occurredAt: DateTime(2026, 3, 17),
          ),
          ExpenseItem(
            id: 2,
            title: 'Fuel',
            category: 'Transport',
            amountKes: 300,
            occurredAt: DateTime(2026, 3, 10),
          ),
        ],
      ),
      incomes: [
        IncomeItem(
          id: 1,
          title: 'Salary',
          amountKes: 3000,
          receivedAt: DateTime(2026, 3, 18),
          source: 'manual',
        ),
        IncomeItem(
          id: 2,
          title: 'Bonus',
          amountKes: 500,
          receivedAt: DateTime(2026, 3, 11),
          source: 'manual',
        ),
      ],
      tasks: [
        TaskItem(
          id: 1,
          title: 'Plan week',
          description: null,
          dueDate: DateTime(2026, 3, 19),
          priority: TaskPriority.high,
          completed: true,
        ),
        TaskItem(
          id: 2,
          title: 'Budget review',
          description: null,
          dueDate: DateTime(2026, 3, 20),
          priority: TaskPriority.medium,
          completed: false,
        ),
      ],
      upcomingEventsCount: 2,
      now: DateTime(2026, 3, 21),
    );

    expect(data.weeklySpendKes, 500);
    expect(data.previousWeeklySpendKes, 300);
    expect(data.weeklyIncomeKes, 3000);
    expect(data.previousWeeklyIncomeKes, 500);
    expect(data.completedThisWeek, 1);
    expect(data.tasksDueThisWeek, 2);
    expect(data.pendingCount, 1);
    expect(data.upcomingEventsCount, 2);
  });
}
