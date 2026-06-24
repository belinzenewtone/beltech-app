import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/review/domain/entities/week_review_data.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';

class BuildWeekReviewDataUseCase {
  const BuildWeekReviewDataUseCase();

  WeekReviewData call({
    required ExpensesSnapshot expenses,
    required List<IncomeItem> incomes,
    required List<TaskItem> tasks,
    required int upcomingEventsCount,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final dayStart = DateTime(anchor.year, anchor.month, anchor.day);
    final weekStart = dayStart.subtract(Duration(days: dayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));

    bool inRange(DateTime date, DateTime start, DateTime end) {
      return !date.isBefore(start) && date.isBefore(end);
    }

    final weeklySpendKes = expenses.transactions
        .where((tx) => inRange(tx.occurredAt, weekStart, weekEnd))
        .fold<double>(0, (sum, tx) => sum + tx.amountKes);
    final previousWeeklySpendKes = expenses.transactions
        .where((tx) => inRange(tx.occurredAt, previousWeekStart, weekStart))
        .fold<double>(0, (sum, tx) => sum + tx.amountKes);

    final weeklyIncomeKes = incomes
        .where((income) => inRange(income.receivedAt, weekStart, weekEnd))
        .fold<double>(0, (sum, income) => sum + income.amountKes);
    final previousWeeklyIncomeKes = incomes
        .where(
          (income) => inRange(income.receivedAt, previousWeekStart, weekStart),
        )
        .fold<double>(0, (sum, income) => sum + income.amountKes);

    final tasksDueThisWeek = tasks.where((task) {
      final dueDate = task.dueDate;
      return dueDate != null && inRange(dueDate, weekStart, weekEnd);
    }).toList();
    final tasksDueLastWeek = tasks.where((task) {
      final dueDate = task.dueDate;
      return dueDate != null && inRange(dueDate, previousWeekStart, weekStart);
    }).toList();

    final completedThisWeek =
        tasksDueThisWeek.where((task) => task.completed).length;
    final completedLastWeek =
        tasksDueLastWeek.where((task) => task.completed).length;
    final pendingCount = tasks.where((task) => !task.completed).length;

    return WeekReviewData(
      completedThisWeek: completedThisWeek,
      completedLastWeek: completedLastWeek,
      pendingCount: pendingCount,
      tasksDueThisWeek: tasksDueThisWeek.length,
      tasksDueLastWeek: tasksDueLastWeek.length,
      weeklySpendKes: weeklySpendKes,
      previousWeeklySpendKes: previousWeeklySpendKes,
      weeklyIncomeKes: weeklyIncomeKes,
      previousWeeklyIncomeKes: previousWeeklyIncomeKes,
      upcomingEventsCount: upcomingEventsCount,
      insights: const [],
    );
  }
}
