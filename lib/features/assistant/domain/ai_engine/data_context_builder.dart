import 'dart:math';

import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';

/// Builds a [DataContext] by querying local repositories.
/// This is a pure orchestrator; repository access is injected via callbacks
/// to keep the engine decoupled from concrete repository implementations.
class DataContextBuilder {
  const DataContextBuilder();

  Future<DataContext> build({
    required Future<double> totalBalance,
    required Future<double> todaySpending,
    required Future<double> weekSpending,
    required Future<double> monthSpending,
    required Future<double> monthIncome,
    required Future<int> pendingTasksCount,
    required Future<int> overdueTasksCount,
    required Future<int> weekEventsCount,
    required Future<List<(String, double)>> topCategories,
    required Future<List<RecentTransaction>> recentTransactions,
    required Future<List<UpcomingBill>> billsUpcoming,
    required Future<List<UpcomingBill>> billsOverdue,
    required Future<double> loansOutstanding,
    required Future<int> loansActiveCount,
    required Future<List<GoalSummary>> goals,
    required Future<int> learningStreak,
    required Future<int> monthlyLearningMinutes,
  }) async {
    return DataContext(
      totalBalance: await totalBalance,
      todaySpending: await todaySpending,
      weekSpending: await weekSpending,
      monthSpending: await monthSpending,
      monthIncome: await monthIncome,
      pendingTasksCount: await pendingTasksCount,
      overdueTasksCount: await overdueTasksCount,
      weekEventsCount: await weekEventsCount,
      topCategories: await topCategories,
      recentTransactions: await recentTransactions,
      billsUpcoming: await billsUpcoming,
      billsOverdue: await billsOverdue,
      loansOutstanding: await loansOutstanding,
      loansActiveCount: await loansActiveCount,
      goals: await goals,
      learningStreak: await learningStreak,
      monthlyLearningMinutes: await monthlyLearningMinutes,
    );
  }

  /// Lightweight variant for quick replies where only a subset of data is needed.
  Future<DataContext> buildMinimal({
    required Future<double> todaySpending,
    required Future<double> monthSpending,
    required Future<int> pendingTasksCount,
    required Future<int> weekEventsCount,
  }) async {
    return DataContext(
      todaySpending: await todaySpending,
      monthSpending: await monthSpending,
      pendingTasksCount: await pendingTasksCount,
      weekEventsCount: await weekEventsCount,
    );
  }
}
