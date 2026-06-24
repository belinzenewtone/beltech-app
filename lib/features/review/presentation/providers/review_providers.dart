import 'package:beltech/core/di/review_use_case_providers.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/home/presentation/providers/home_providers.dart';
import 'package:beltech/features/income/presentation/providers/income_providers.dart';
import 'package:beltech/features/review/domain/entities/week_review_data.dart';
import 'package:beltech/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Re-export domain entities so existing import paths continue to work.
export 'package:beltech/features/review/domain/entities/week_review_data.dart'
    show WeekReviewData, WeekReviewInsight, WeekReviewInsightTone;

/// Derives week review data from expenses, income, tasks and home overview.
final weekReviewDataProvider = Provider<AsyncValue<WeekReviewData>>((ref) {
  final overviewState = ref.watch(homeOverviewProvider);
  final expensesState = ref.watch(expensesSnapshotProvider);
  final incomesState = ref.watch(incomesProvider);
  final tasksState = ref.watch(tasksProvider);

  if (overviewState.isLoading ||
      expensesState.isLoading ||
      incomesState.isLoading ||
      tasksState.isLoading) {
    return const AsyncLoading();
  }
  if (overviewState.hasError) {
    return AsyncError(
      overviewState.error!,
      overviewState.stackTrace ?? StackTrace.current,
    );
  }
  if (expensesState.hasError) {
    return AsyncError(
      expensesState.error!,
      expensesState.stackTrace ?? StackTrace.current,
    );
  }
  if (incomesState.hasError) {
    return AsyncError(
      incomesState.error!,
      incomesState.stackTrace ?? StackTrace.current,
    );
  }
  if (tasksState.hasError) {
    return AsyncError(
      tasksState.error!,
      tasksState.stackTrace ?? StackTrace.current,
    );
  }

  final overview = overviewState.valueOrNull;
  final expenses = expensesState.valueOrNull;
  final incomes = incomesState.valueOrNull;
  final tasks = tasksState.valueOrNull;
  if (overview == null ||
      expenses == null ||
      incomes == null ||
      tasks == null) {
    return const AsyncLoading();
  }

  final data = ref.watch(buildWeekReviewDataUseCaseProvider).call(
        expenses: expenses,
        incomes: incomes,
        tasks: tasks,
        upcomingEventsCount: overview.upcomingEventsCount,
      );

  return AsyncData(
    WeekReviewData(
      completedThisWeek: data.completedThisWeek,
      completedLastWeek: data.completedLastWeek,
      pendingCount: data.pendingCount,
      tasksDueThisWeek: data.tasksDueThisWeek,
      tasksDueLastWeek: data.tasksDueLastWeek,
      weeklySpendKes: data.weeklySpendKes,
      previousWeeklySpendKes: data.previousWeeklySpendKes,
      weeklyIncomeKes: data.weeklyIncomeKes,
      previousWeeklyIncomeKes: data.previousWeeklyIncomeKes,
      upcomingEventsCount: data.upcomingEventsCount,
      insights: _buildInsights(data),
    ),
  );
});

List<WeekReviewInsight> _buildInsights(WeekReviewData data) {
  final insights = <WeekReviewInsight>[];

  final spendDelta = data.spendDeltaKes;
  if (spendDelta <= -250) {
    insights.add(
      WeekReviewInsight(
        title: 'Spending improved',
        detail:
            'You spent ${_money(spendDelta.abs())} less than last week. Keep this pace.',
        tone: WeekReviewInsightTone.positive,
      ),
    );
  } else if (spendDelta >= 250) {
    insights.add(
      WeekReviewInsight(
        title: 'Spending is up',
        detail:
            'You spent ${_money(spendDelta)} more than last week. Review top categories.',
        tone: WeekReviewInsightTone.caution,
      ),
    );
  } else {
    insights.add(
      const WeekReviewInsight(
        title: 'Spending is stable',
        detail: 'Your spending is close to last week.',
        tone: WeekReviewInsightTone.neutral,
      ),
    );
  }

  if (data.netKes >= 0 && data.netDeltaKes >= 0) {
    insights.add(
      WeekReviewInsight(
        title: 'Positive cash flow',
        detail:
            'You stayed positive by ${_money(data.netKes)} this week, improving by ${_money(data.netDeltaKes)}.',
        tone: WeekReviewInsightTone.positive,
      ),
    );
  } else if (data.netKes < 0) {
    insights.add(
      WeekReviewInsight(
        title: 'Negative cash flow',
        detail:
            'Expenses exceeded income by ${_money(data.netKes.abs())}. Consider trimming discretionary spend.',
        tone: WeekReviewInsightTone.caution,
      ),
    );
  } else {
    insights.add(
      WeekReviewInsight(
        title: 'Cash flow mixed',
        detail:
            'Net this week is ${_money(data.netKes)}. A small income boost can improve next week.',
        tone: WeekReviewInsightTone.neutral,
      ),
    );
  }

  if (data.tasksDueThisWeek == 0) {
    insights.add(
      const WeekReviewInsight(
        title: 'No due-date workload',
        detail: 'Set due dates for key tasks to get clearer momentum tracking.',
        tone: WeekReviewInsightTone.neutral,
      ),
    );
  } else if (data.completionRateThisWeek >= 0.7) {
    insights.add(
      WeekReviewInsight(
        title: 'Great execution',
        detail:
            'You completed ${_percent(data.completionRateThisWeek)} of tasks due this week.',
        tone: WeekReviewInsightTone.positive,
      ),
    );
  } else {
    insights.add(
      WeekReviewInsight(
        title: 'Task follow-through can improve',
        detail:
            'You completed ${_percent(data.completionRateThisWeek)} of due tasks. Try focusing on top priorities first.',
        tone: WeekReviewInsightTone.caution,
      ),
    );
  }

  return insights;
}

String _money(double value) {
  return 'KES ${value.toStringAsFixed(0)}';
}

String _percent(double value) {
  return '${(value * 100).toStringAsFixed(0)}%';
}
