import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/budget/domain/entities/budget.dart';
import 'package:beltech/features/budget/presentation/providers/budget_providers.dart';
import 'package:beltech/features/expenses/domain/entities/expense.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_rule.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';
import 'package:beltech/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:beltech/features/insights/domain/usecases/generate_spend_insights_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spend insights generator use case provider.
final generateSpendInsightsUseCaseProvider =
    Provider((ref) => GenerateSpendInsightsUseCase());

/// Provider for generating spending insights based on current data.
/// Returns a list of insights sorted by severity (alerts first, warnings, then info).
final spendInsightsProvider = FutureProvider<List<SpendInsight>>((ref) async {
  final expensesSnapshot = ref.watch(expensesSnapshotProvider);
  final budgetSnapshot = ref.watch(budgetSnapshotProvider);
  final recurringTemplates = ref.watch(recurringTemplatesProvider);
  final useCase = ref.watch(generateSpendInsightsUseCaseProvider);

  // Wait for all data to load
  final isLoading = expensesSnapshot.isLoading ||
      budgetSnapshot.isLoading ||
      recurringTemplates.isLoading;
  if (isLoading) return [];

  final expenseItems = expensesSnapshot.valueOrNull?.transactions ?? [];
  final budget = budgetSnapshot.valueOrNull;
  final templates = recurringTemplates.valueOrNull ?? [];

  // Calculate time windows for insights
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);
  final lastMonth = DateTime(now.year, now.month - 1, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);

  final thisMonthStart = currentMonth;
  final thisMonthEnd = nextMonth.subtract(const Duration(days: 1));

  final lastMonthStart = lastMonth;
  final lastMonthEnd = currentMonth.subtract(const Duration(days: 1));

  final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
  final thisWeekEnd = thisWeekStart.add(const Duration(days: 7));

  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));

  // Convert ExpenseItem to Expense for insights processing
  final _toExpense = (ExpenseItem e) => Expense(
    id: e.id.toString(),
    amount: e.amountKes,
    merchant: e.title,
    description: e.title,
    occurredAt: e.occurredAt,
    category: e.category,
  );

  // Convert RecurringTemplate to RecurringRule (only expense rules that are active)
  final _toRule = (RecurringTemplate t) => RecurringRule(
    id: t.id.toString(),
    name: t.title,
    merchant: t.description ?? t.title,
    nextRunAt: t.nextRunAt,
    isActive: t.enabled && t.kind == RecurringKind.expense,
  );

  // Filter expenses by date range
  final currentMonthExpenses = expenseItems
      .where((e) =>
          e.occurredAt.isAfter(thisMonthStart) &&
          e.occurredAt.isBefore(thisMonthEnd))
      .map(_toExpense)
      .toList();

  final lastMonthExpenses = expenseItems
      .where((e) =>
          e.occurredAt.isAfter(lastMonthStart) &&
          e.occurredAt.isBefore(lastMonthEnd))
      .map(_toExpense)
      .toList();

  final thisWeekExpenses = expenseItems
      .where((e) =>
          e.occurredAt.isAfter(thisWeekStart) &&
          e.occurredAt.isBefore(thisWeekEnd))
      .map(_toExpense)
      .toList();

  final lastWeekExpenses = expenseItems
      .where((e) =>
          e.occurredAt.isAfter(lastWeekStart) &&
          e.occurredAt.isBefore(lastWeekEnd))
      .map(_toExpense)
      .toList();

  // Create a Budget entity from BudgetSnapshot if available
  Budget? activeBudget;
  if (budget != null && budget.items.isNotEmpty) {
    activeBudget = Budget(
      id: 'budget_${budget.month.year}_${budget.month.month}',
      name: 'Monthly Budget',
      amount: budget.totalLimitKes,
      period: 'monthly',
      isActive: true,
    );
  }

  // Convert recurring templates to rules
  final recurringRules = templates.map(_toRule).toList();

  // Generate insights using the use case
  return useCase.generateInsights(
    currentMonthExpenses: currentMonthExpenses,
    lastMonthExpenses: lastMonthExpenses,
    thisWeekExpenses: thisWeekExpenses,
    lastWeekExpenses: lastWeekExpenses,
    activeBudget: activeBudget,
    recurringRules: recurringRules,
  );
});
