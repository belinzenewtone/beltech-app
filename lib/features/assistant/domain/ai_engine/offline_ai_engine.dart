import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/features/assistant/domain/ai_engine/anomaly_detector.dart';
import 'package:beltech/features/assistant/domain/ai_engine/cash_flow_projector.dart';
import 'package:beltech/features/assistant/domain/ai_engine/data_context_builder.dart';
import 'package:beltech/features/assistant/domain/ai_engine/financial_health_calculator.dart';
import 'package:beltech/features/assistant/domain/ai_engine/intent_classifier.dart';
import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';

/// Orchestrates the offline AI pipeline:
/// 1. Classify intent
/// 2. Build data context (when needed)
/// 3. Run relevant calculators/detectors/projectors
/// 4. Generate a natural-language reply
class OfflineAiEngine {
  const OfflineAiEngine({
    this.contextBuilder = const DataContextBuilder(),
    this.healthCalculator = const FinancialHealthCalculator(),
    this.anomalyDetector = const AnomalyDetector(),
    this.cashFlowProjector = const CashFlowProjector(),
    this.intentClassifier = const IntentClassifier(),
  });

  final DataContextBuilder contextBuilder;
  final FinancialHealthCalculator healthCalculator;
  final AnomalyDetector anomalyDetector;
  final CashFlowProjector cashFlowProjector;
  final IntentClassifier intentClassifier;

  /// Generates a reply for the given [query] using the provided data suppliers.
  /// All suppliers are async callbacks that fetch from local repositories.
  Future<String> reply({
    required String query,
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
    required Future<double> avgDailyIncome,
    required Future<double> avgDailyExpense,
    required Future<List<LoanPayment>> loanPayments,
  }) async {
    final intent = intentClassifier.classify(query);

    // For simple intents, use minimal context to avoid heavy queries
    final needsFullContext = !_isSimpleIntent(intent);

    final DataContext ctx;
    if (needsFullContext) {
      ctx = await contextBuilder.build(
        totalBalance: totalBalance,
        todaySpending: todaySpending,
        weekSpending: weekSpending,
        monthSpending: monthSpending,
        monthIncome: monthIncome,
        pendingTasksCount: pendingTasksCount,
        overdueTasksCount: overdueTasksCount,
        weekEventsCount: weekEventsCount,
        topCategories: topCategories,
        recentTransactions: recentTransactions,
        billsUpcoming: billsUpcoming,
        billsOverdue: billsOverdue,
        loansOutstanding: loansOutstanding,
        loansActiveCount: loansActiveCount,
        goals: goals,
        learningStreak: learningStreak,
        monthlyLearningMinutes: monthlyLearningMinutes,
      );
    } else {
      ctx = await contextBuilder.buildMinimal(
        todaySpending: todaySpending,
        monthSpending: monthSpending,
        pendingTasksCount: pendingTasksCount,
        weekEventsCount: weekEventsCount,
      );
    }

    return _generateReply(
      intent,
      query,
      ctx,
      recentTransactions: await recentTransactions,
      avgDailyIncome: await avgDailyIncome,
      avgDailyExpense: await avgDailyExpense,
      loanPayments: await loanPayments,
      totalBalance: await totalBalance,
    );
  }

  bool _isSimpleIntent(Intent intent) => switch (intent) {
    Intent.spendingSummary ||
    Intent.incomeSummary ||
    Intent.balanceCheck ||
    Intent.taskSummary ||
    Intent.eventSummary => true,
    _ => false,
  };

  String _generateReply(
    Intent intent,
    String query,
    DataContext ctx, {
    required List<RecentTransaction> recentTransactions,
    required double avgDailyIncome,
    required double avgDailyExpense,
    required List<LoanPayment> loanPayments,
    required double totalBalance,
  }) {
    switch (intent) {
      case Intent.spendingSummary:
        return _spendingReply(ctx);
      case Intent.incomeSummary:
        return _incomeReply(ctx);
      case Intent.balanceCheck:
        return 'Your total balance is ${CurrencyFormatter.money(totalBalance)}. '
            'This month you have spent ${CurrencyFormatter.money(ctx.monthSpending)} '
            'and earned ${CurrencyFormatter.money(ctx.monthIncome)}.';
      case Intent.taskSummary:
        final overdue = ctx.overdueTasksCount > 0
            ? ' You have ${ctx.overdueTasksCount} overdue task(s).'
            : '';
        return 'You have ${ctx.pendingTasksCount} pending task(s).$overdue';
      case Intent.eventSummary:
        return 'You have ${ctx.weekEventsCount} event(s) this week.';
      case Intent.healthCheck:
        final score = healthCalculator.calculate(ctx);
        final label = healthCalculator.healthLabel(score);
        return 'Your financial health score is $score/100 ($label). '
            '${_healthAdvice(score, ctx)}';
      case Intent.anomalyAlert:
        final anomalies = anomalyDetector.detect(recentTransactions);
        if (anomalies.isEmpty) {
          return 'No anomalies detected. Your data looks clean.';
        }
        final high = anomalies
            .where((a) => a.severity == AnomalySeverity.high)
            .length;
        final lines = anomalies
            .take(3)
            .map((a) => '• ${a.description}')
            .join('\n');
        return 'Found ${anomalies.length} anomaly(ies). High severity: $high.\n$lines';
      case Intent.cashFlowProjection:
        final projection = cashFlowProjector.project(
          currentBalance: totalBalance,
          avgDailyIncome: avgDailyIncome,
          avgDailyExpense: avgDailyExpense,
          upcomingBills: ctx.billsUpcoming,
          loanPayments: loanPayments,
          days: 30,
        );
        final (lowBal, lowDate) = cashFlowProjector.findLowestPoint(projection);
        final lowText = lowDate != null
            ? ' Lowest projected balance is ${CurrencyFormatter.money(lowBal)} on ${lowDate.day}/${lowDate.month}.'
            : '';
        return 'Projected cash flow for the next 30 days looks stable.$lowText';
      case Intent.goalSummary:
        if (ctx.goals.isEmpty) return 'You have no active goals.';
        final atRisk = ctx.goals.where((g) => g.atRisk).length;
        final lines = ctx.goals
            .take(3)
            .map((g) {
              final pct = (g.progressPercent * 100).toStringAsFixed(0);
              return '• ${g.title}: $pct% (${CurrencyFormatter.money(g.current)}/${CurrencyFormatter.money(g.target)})';
            })
            .join('\n');
        return 'You have ${ctx.goals.length} goal(s). At risk: $atRisk.\n$lines';
      case Intent.loanSummary:
        if (ctx.loansActiveCount == 0) return 'You have no active loans.';
        return 'You have ${ctx.loansActiveCount} active loan(s) with an outstanding balance of ${CurrencyFormatter.money(ctx.loansOutstanding)}.';
      case Intent.billSummary:
        if (ctx.billsUpcoming.isEmpty && ctx.billsOverdue.isEmpty) {
          return 'No upcoming or overdue bills. Great job!';
        }
        final overdue = ctx.billsOverdue.isNotEmpty
            ? ' Overdue: ${ctx.billsOverdue.length}.'
            : '';
        final next = ctx.billsUpcoming.isNotEmpty
            ? ' Next due: "${ctx.billsUpcoming.first.name}" in ${ctx.billsUpcoming.first.daysUntil} day(s).'
            : '';
        return 'Upcoming bills: ${ctx.billsUpcoming.length}.$overdue$next';
      case Intent.learningSummary:
        return 'Learning streak: ${ctx.learningStreak} day(s). This month: ${ctx.monthlyLearningMinutes} minute(s).';
      case Intent.financialAdvice:
        return _financialAdvice(ctx);
      case Intent.spendingComparison:
        return _comparisonReply(ctx);
      case Intent.merchantSummary:
        return _merchantReply(recentTransactions);
      case Intent.exportData:
        return 'You can export your data from the Export screen in Settings.';
      case Intent.categoryBreakdown:
        return _categoryReply(ctx);
      case Intent.unknown:
        return _fallbackReply(ctx);
    }
  }

  String _spendingReply(DataContext ctx) {
    final today = CurrencyFormatter.money(ctx.todaySpending);
    final week = CurrencyFormatter.money(ctx.weekSpending);
    final month = CurrencyFormatter.money(ctx.monthSpending);
    if (ctx.todaySpending > 0) {
      return 'Today: $today. This week: $week. This month: $month.';
    }
    return 'No spending recorded today. This month: $month.';
  }

  String _incomeReply(DataContext ctx) {
    return 'This month you have earned ${CurrencyFormatter.money(ctx.monthIncome)}.';
  }

  String _healthAdvice(int score, DataContext ctx) {
    if (score >= 80) {
      return 'Keep it up! Your savings rate and task discipline are strong.';
    }
    if (score >= 60) {
      if (ctx.billsOverdue.isNotEmpty) {
        return 'Consider clearing overdue bills to improve your score.';
      }
      if (ctx.loansOutstanding > 0) {
        return 'Try reducing loan burden to boost your health.';
      }
      return 'You are doing okay. Small improvements in savings will help.';
    }
    if (ctx.overdueTasksCount > 0) {
      return 'Address overdue tasks and reduce spending spikes.';
    }
    if (ctx.monthIncome > 0 && ctx.monthSpending > ctx.monthIncome) {
      return 'Warning: You are spending more than you earn. Review your budget.';
    }
    return 'Focus on reducing expenses and building a savings buffer.';
  }

  String _financialAdvice(DataContext ctx) {
    final tips = <String>[];
    if (ctx.monthIncome > 0) {
      final rate = (ctx.monthIncome - ctx.monthSpending) / ctx.monthIncome;
      if (rate < 0.1) tips.add('Try to save at least 10% of your income.');
      if (rate < 0) {
        tips.add('Your expenses exceed income. Prioritize essential spending.');
      }
    }
    if (ctx.billsUpcoming.isNotEmpty) {
      tips.add(
        'You have ${ctx.billsUpcoming.length} upcoming bill(s). Plan ahead.',
      );
    }
    if (ctx.goals.isNotEmpty) {
      final atRisk = ctx.goals.where((g) => g.atRisk).length;
      if (atRisk > 0) {
        tips.add(
          '$atRisk goal(s) are at risk. Consider increasing contributions.',
        );
      }
    }
    if (tips.isEmpty) {
      return 'You are on a good path. Keep tracking consistently.';
    }
    return tips.join(' ');
  }

  String _comparisonReply(DataContext ctx) {
    if (ctx.monthIncome > 0 && ctx.monthSpending > ctx.monthIncome) {
      return 'You are spending ${CurrencyFormatter.money(ctx.monthSpending - ctx.monthIncome)} more than you earn this month.';
    }
    return 'Spending vs income looks balanced this month.';
  }

  String _merchantReply(List<RecentTransaction> txs) {
    if (txs.isEmpty) return 'No recent transactions to analyze.';
    final byTitle = <String, double>{};
    for (final tx in txs.where((t) => t.type == 'expense')) {
      byTitle[tx.title] = (byTitle[tx.title] ?? 0) + tx.amount;
    }
    final sorted = byTitle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted
        .take(3)
        .map((e) => '• ${e.key}: ${CurrencyFormatter.money(e.value)}')
        .join('\n');
    return 'Top merchants by spending:\n$top';
  }

  String _categoryReply(DataContext ctx) {
    if (ctx.topCategories.isEmpty) return 'No category data available.';
    final lines = ctx.topCategories
        .take(5)
        .map((c) => '• ${c.$1}: ${CurrencyFormatter.money(c.$2)}')
        .join('\n');
    return 'Spending by category:\n$lines';
  }

  String _fallbackReply(DataContext ctx) {
    final health = healthCalculator.calculate(ctx);
    final label = healthCalculator.healthLabel(health);
    return 'I am not sure how to answer that. Here is a quick summary: '
        'Health score $health/100 ($label). '
        'Spending this month: ${CurrencyFormatter.money(ctx.monthSpending)}. '
        'Pending tasks: ${ctx.pendingTasksCount}.';
  }
}
