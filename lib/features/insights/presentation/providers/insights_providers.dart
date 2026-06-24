import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/budget/presentation/providers/budget_providers.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/income/presentation/providers/income_providers.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:beltech/features/bills/presentation/providers/bills_providers.dart';
import 'package:beltech/features/insights/domain/entities/insight_card.dart';
import 'package:beltech/features/insights/domain/entities/insight_helpers.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final insightsProvider = FutureProvider<List<InsightCard>>((ref) async {
  final expensesState = ref.watch(expensesSnapshotProvider);
  final budgetState = ref.watch(budgetSnapshotProvider);
  final tasksState = ref.watch(tasksProvider);
  final incomesState = ref.watch(incomesProvider);
  final billsState = ref.watch(billsProvider);

  final isLoading = expensesState.isLoading ||
      budgetState.isLoading ||
      tasksState.isLoading ||
      incomesState.isLoading ||
      billsState.isLoading;
  if (isLoading) return [];

  final transactions = (expensesState.valueOrNull?.transactions ?? const [])
      .toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final categories = expensesState.valueOrNull?.categories ?? const [];
  final budgetSnapshot = budgetState.valueOrNull;
  final tasks = tasksState.valueOrNull ?? const [];
  final incomes = incomesState.valueOrNull ?? const [];
  final bills = billsState.valueOrNull ?? const [];

  final cards = <InsightCard>[];
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);
  final lastMonth = DateTime(now.year, now.month - 1, 1);

  final thisMonthTxns = transactions
      .where((t) =>
          t.occurredAt.year == currentMonth.year &&
          t.occurredAt.month == currentMonth.month)
      .toList();
  final lastMonthTxns = transactions
      .where((t) =>
          t.occurredAt.year == lastMonth.year &&
          t.occurredAt.month == lastMonth.month)
      .toList();

  final thisMonthTotal =
      thisMonthTxns.fold<double>(0, (s, t) => s + t.amountKes);
  final lastMonthTotal =
      lastMonthTxns.fold<double>(0, (s, t) => s + t.amountKes);

  _addSpendComparison(cards, now, thisMonthTotal, lastMonthTotal);
  _addTopCategory(cards, now, categories);
  _addTaskCompletion(cards, now, tasks);
  _addBudgetAdherence(cards, now, budgetSnapshot);
  _addUnusualSpending(cards, now, thisMonthTxns, thisMonthTotal);
  _addUpcomingBills(cards, now, bills);
  _addSavingsRate(cards, now, incomes, thisMonthTotal, currentMonth);

  cards.add(generalTipInsight(now));

  return cards;
});

void _addSpendComparison(
  List<InsightCard> cards,
  DateTime now,
  double thisMonthTotal,
  double lastMonthTotal,
) {
  if (thisMonthTotal <= 0 || lastMonthTotal <= 0) return;
  final delta = thisMonthTotal - lastMonthTotal;
  final pctChange = (delta / lastMonthTotal * 100).abs().round();
  if (pctChange < 15) return;

  if (delta > 0) {
    cards.add(InsightCard(
      id: 'spend-increase-monthly',
      kind: InsightKind.spending,
      title: 'Spending is up this month',
      body:
          'Spending is ${pctChange}% higher this month '
          '(KES ${thisMonthTotal.toStringAsFixed(0)} vs '
          'KES ${lastMonthTotal.toStringAsFixed(0)} last month).',
      tone: InsightTone.warning,
      confidence: 0.85,
      generatedAt: now,
      actionRoute: 'budget',
    ));
  } else {
    cards.add(InsightCard(
      id: 'spend-decrease-monthly',
      kind: InsightKind.spending,
      title: 'Spending is down this month',
      body:
          'Spending is ${pctChange}% lower this month. '
          'Great work keeping expenses under control.',
      tone: InsightTone.positive,
      confidence: 0.85,
      generatedAt: now,
      actionRoute: 'budget',
    ));
  }
}
void _addTopCategory(
  List<InsightCard> cards,
  DateTime now,
  List<CategoryExpenseTotal> categories,
) {
  if (categories.isEmpty) return;
  final sorted = categories.toList()
    ..sort((a, b) => b.totalKes.compareTo(a.totalKes));
  final top = sorted.first;

  cards.add(InsightCard(
    id: 'top-category',
    kind: InsightKind.spending,
    title: 'Top category: ${top.category}',
    body:
        'Your highest spending this period is ${top.category} at '
        'KES ${top.totalKes.toStringAsFixed(0)}. Look for opportunities '
        'to reduce spending in this area.',
    tone: InsightTone.neutral,
    confidence: 0.9,
    generatedAt: now,
    actionRoute: 'analytics',
  ));
}

void _addTaskCompletion(
  List<InsightCard> cards,
  DateTime now,
  List<TaskItem> tasks,
) {
  if (tasks.isEmpty) return;
  final completed = tasks.where((t) => t.completed).length;
  final total = tasks.length;
  final rate = (completed / total * 100).round();

  if (rate >= 100) {
    cards.add(InsightCard(
      id: 'tasks-all-done',
      kind: InsightKind.taskCompletion,
      title: 'All tasks completed',
      body: 'You completed all $total tasks. Excellent productivity.',
      tone: InsightTone.positive,
      confidence: 0.95,
      generatedAt: now,
      actionRoute: 'tasks',
    ));
  } else if (rate < 30 && total > 2) {
    cards.add(InsightCard(
      id: 'tasks-behind',
      kind: InsightKind.taskCompletion,
      title: '$completed of $total tasks completed',
      body:
          'You have only completed $rate% of your tasks. Consider '
          'prioritizing your to-do list or breaking larger tasks '
          'into smaller steps.',
      tone: InsightTone.warning,
      confidence: 0.8,
      generatedAt: now,
      actionRoute: 'tasks',
    ));
  }
}

void _addBudgetAdherence(
  List<InsightCard> cards,
  DateTime now,
  BudgetSnapshot? budgetSnapshot,
) {
  if (budgetSnapshot == null) return;
  final overBudgetTargets = budgetSnapshot.items
      .where((item) => item.usageRatio >= 0.9)
      .toList();

  for (final item in overBudgetTargets) {
    final pct = (item.usageRatio * 100).round();
    if (pct >= 100) {
      cards.add(InsightCard(
        id: 'budget-over-${item.category}',
        kind: InsightKind.budget,
        title: 'Budget over: ${item.category}',
        body:
            'You have exceeded the ${item.category} budget '
            '(KES ${item.spentKes.toStringAsFixed(0)} spent of '
            'KES ${item.monthlyLimitKes.toStringAsFixed(0)} limit). '
            'Consider adjusting spending or increasing the budget.',
        tone: InsightTone.warning,
        confidence: 0.9,
        generatedAt: now,
        actionRoute: 'budget',
      ));
    }
  }
}

void _addUnusualSpending(
  List<InsightCard> cards,
  DateTime now,
  List<ExpenseItem> thisMonthTxns,
  double thisMonthTotal,
) {
  if (thisMonthTxns.isEmpty) return;
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final dailyAvg = thisMonthTotal / daysInMonth;
  final outliers = thisMonthTxns
      .where((t) => t.amountKes > dailyAvg * 2 && t.amountKes > 500)
      .toList();

  if (outliers.isEmpty) return;
  final topOutlier = outliers
    ..sort((a, b) => b.amountKes.compareTo(a.amountKes));
  final t = topOutlier.first;

  cards.add(InsightCard(
    id: 'unusual-spend-${t.id}',
    kind: InsightKind.anomaly,
    title: 'Unusual transaction: ${t.title}',
    body:
        'A KES ${t.amountKes.toStringAsFixed(0)} transaction in '
        '${t.category} is more than double your daily average '
        '(KES ${dailyAvg.toStringAsFixed(0)}). This may warrant '
        'a second look.',
    tone: InsightTone.info,
    confidence: 0.6,
    generatedAt: now,
    actionRoute: null,
  ));
}

void _addUpcomingBills(
  List<InsightCard> cards,
  DateTime now,
  List<BillItem> bills,
) {
  final upcoming = bills
      .where((b) => !b.paid && b.dueDate.isAfter(now))
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  final dueIn7Days = upcoming
      .where((b) => b.dueDate.difference(now).inDays <= 7)
      .toList();

  if (dueIn7Days.isEmpty) return;
  final totalDue = dueIn7Days.fold<double>(0, (s, b) => s + b.amount);
  cards.add(InsightCard(
    id: 'upcoming-bills',
    kind: InsightKind.budget,
    title: '${dueIn7Days.length} bill(s) due soon',
    body:
        'KES ${totalDue.toStringAsFixed(0)} in bills due within '
        '7 days. Make sure you have enough funds to cover them.',
    tone: InsightTone.warning,
    confidence: 0.95,
    generatedAt: now,
    actionRoute: 'bills',
  ));
}

void _addSavingsRate(
  List<InsightCard> cards,
  DateTime now,
  List<IncomeItem> incomes,
  double thisMonthTotal,
  DateTime currentMonth,
) {
  final monthIncome = incomes
      .where((i) =>
          i.receivedAt.year == currentMonth.year &&
          i.receivedAt.month == currentMonth.month)
      .fold<double>(0, (s, i) => s + i.amountKes);
  if (monthIncome <= 0 || monthIncome <= thisMonthTotal) return;

  final savings = monthIncome - thisMonthTotal;
  final savingsRate = (savings / monthIncome * 100).round();
  if (savingsRate < 10) return;

  cards.add(InsightCard(
    id: 'savings-rate',
    kind: InsightKind.cashFlow,
    title: 'Healthy savings rate: $savingsRate%',
    body:
        'Saved KES ${savings.toStringAsFixed(0)} this month '
        '($savingsRate% of income). Consider investing or '
        'building your emergency fund.',
    tone: InsightTone.positive,
    confidence: 0.8,
    generatedAt: now,
    actionRoute: 'goals',
  ));
}
