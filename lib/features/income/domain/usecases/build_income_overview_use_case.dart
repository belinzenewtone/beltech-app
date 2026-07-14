import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/income/domain/entities/income_overview.dart';
import 'package:intl/intl.dart';

class BuildIncomeOverviewUseCase {
  const BuildIncomeOverviewUseCase();

  IncomeOverview call({
    required List<IncomeItem> incomes,
    required List<ExpenseItem> expenseTransactions,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final monthStart = DateTime(clock.year, clock.month, 1);
    final nextMonthStart = DateTime(clock.year, clock.month + 1, 1);

    final totalIncomeKes = incomes.fold<double>(
      0,
      (sum, item) => sum + item.amountKes,
    );
    final currentMonthIncomeKes = incomes
        .where(
          (item) =>
              !item.receivedAt.isBefore(monthStart) &&
              item.receivedAt.isBefore(nextMonthStart),
        )
        .fold<double>(0, (sum, item) => sum + item.amountKes);
    final currentMonthExpenseKes = expenseTransactions
        .where(
          (item) =>
              !item.occurredAt.isBefore(monthStart) &&
              item.occurredAt.isBefore(nextMonthStart),
        )
        .fold<double>(0, (sum, item) => sum + item.amountKes);

    return IncomeOverview(
      totalIncomeKes: totalIncomeKes,
      currentMonthIncomeKes: currentMonthIncomeKes,
      currentMonthExpenseKes: currentMonthExpenseKes,
      netCashflowKes: currentMonthIncomeKes - currentMonthExpenseKes,
      trend: _buildTrend(incomes),
    );
  }

  List<IncomeTrendPoint> _buildTrend(List<IncomeItem> incomes) {
    if (incomes.isEmpty) {
      return const [];
    }
    final totals = <String, double>{};
    final labels = <String, String>{};
    for (final item in incomes) {
      final monthKey =
          '${item.receivedAt.year}-${item.receivedAt.month.toString().padLeft(2, '0')}';
      totals[monthKey] = (totals[monthKey] ?? 0) + item.amountKes;
      labels.putIfAbsent(
        monthKey,
        () => DateFormat('MMM').format(item.receivedAt),
      );
    }

    final sortedKeys = totals.keys.toList()..sort();
    final recentKeys = sortedKeys.length <= 6
        ? sortedKeys
        : sortedKeys.sublist(sortedKeys.length - 6);

    return recentKeys
        .map(
          (key) => IncomeTrendPoint(
            label: labels[key] ?? key,
            incomeKes: totals[key] ?? 0,
          ),
        )
        .toList();
  }
}
