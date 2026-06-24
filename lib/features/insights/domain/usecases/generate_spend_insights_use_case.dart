/// Spend insights generation use case.
///
/// Generates rule-based spending insights and anomaly alerts based on
/// current spending patterns, budget adherence, recurring transactions,
/// and historical trends.

import 'package:beltech/features/expenses/domain/entities/expense.dart';
import 'package:beltech/features/budget/domain/entities/budget.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_rule.dart';

/// Represents a single insight alert.
class SpendInsight {
  final String id;
  final String title;
  final String description;
  final InsightSeverity severity;
  final InsightType type;
  final String? actionLabel;
  final String? actionRoute;
  final DateTime generatedAt;

  SpendInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    this.actionLabel,
    this.actionRoute,
    required this.generatedAt,
  });
}

/// Insight severity levels.
enum InsightSeverity {
  info,    // Informational
  warning, // Warning (user should review)
  alert,   // Alert (immediate action recommended)
}

/// Insight types.
enum InsightType {
  overBudget,          // Spending ≥110% of budget
  trendSpike,          // Week-over-week increase >30%
  merchantAnomaly,     // Single merchant >20% of week spend
  recurringVariance,   // Expected recurring payment missing
  feeImpact,           // M-Pesa fees >5% of transaction total
}

/// Generate spend insights use case.
class GenerateSpendInsightsUseCase {
  const GenerateSpendInsightsUseCase();

  /// Generate insights based on current spending data.
  ///
  /// Rules applied (in priority order):
  /// 1. **Over-Budget Alert** — If current month spend ≥ 110% of budget
  /// 2. **Trend Detection** — If week-over-week spend up >30%
  /// 3. **Merchant Anomaly** — If single merchant >20% of week spend
  /// 4. **Recurring Variance** — If expected recurring payment due but not found
  /// 5. **Fee Impact** — If M-Pesa fees >5% of transaction total
  List<SpendInsight> generateInsights({
    required List<Expense> currentMonthExpenses,
    required List<Expense> lastMonthExpenses,
    required List<Expense> thisWeekExpenses,
    required List<Expense> lastWeekExpenses,
    required Budget? activeBudget,
    required List<RecurringRule> recurringRules,
  }) {
    final insights = <SpendInsight>[];

    // Rule 1: Over-Budget Alert
    if (activeBudget != null) {
      final monthSpend = _sumExpenseAmount(currentMonthExpenses);
      final budgetThreshold = activeBudget.amount * 1.1;

      if (monthSpend >= budgetThreshold) {
        final percentOver = ((monthSpend / activeBudget.amount) - 1.0) * 100;
        insights.add(
          SpendInsight(
            id: 'over_budget_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Over Budget',
            description:
                'Your spending is ${percentOver.toStringAsFixed(0)}% above your ${activeBudget.name} budget.',
            severity: percentOver > 30 ? InsightSeverity.alert : InsightSeverity.warning,
            type: InsightType.overBudget,
            actionLabel: 'View Budget',
            actionRoute: '/budget',
            generatedAt: DateTime.now(),
          ),
        );
      }
    }

    // Rule 2: Trend Detection (Week-over-Week)
    final thisWeekSpend = _sumExpenseAmount(thisWeekExpenses);
    final lastWeekSpend = _sumExpenseAmount(lastWeekExpenses);

    if (lastWeekSpend > 0) {
      final weekGrowth = ((thisWeekSpend / lastWeekSpend) - 1.0) * 100;

      if (weekGrowth > 30) {
        insights.add(
          SpendInsight(
            id: 'trend_spike_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Spending Spike',
            description:
                'Your spending is up ${weekGrowth.toStringAsFixed(0)}% compared to last week.',
            severity: weekGrowth > 50 ? InsightSeverity.alert : InsightSeverity.warning,
            type: InsightType.trendSpike,
            actionLabel: 'View Analytics',
            actionRoute: '/analytics',
            generatedAt: DateTime.now(),
          ),
        );
      }
    }

    // Rule 3: Merchant Anomaly (Single merchant >20% of week spend)
    if (thisWeekExpenses.isNotEmpty) {
      final merchantTotals = _aggregateByMerchant(thisWeekExpenses);
      final weekTotal = thisWeekSpend;

      if (weekTotal > 0) {
        merchantTotals.forEach((merchant, amount) {
          final merchantPercent = (amount / weekTotal) * 100;

          if (merchantPercent > 20) {
            insights.add(
              SpendInsight(
                id: 'merchant_anomaly_${merchant}_${DateTime.now().millisecondsSinceEpoch}',
                title: 'High Merchant Concentration',
                description:
                    '${merchantPercent.toStringAsFixed(0)}% of your weekly spend is at $merchant.',
                severity: InsightSeverity.info,
                type: InsightType.merchantAnomaly,
                actionLabel: 'View Merchant',
                actionRoute: '/merchant/$merchant',
                generatedAt: DateTime.now(),
              ),
            );
          }
        });
      }
    }

    // Rule 4: Recurring Variance (Expected payment missing)
    final dueRecurring = _getDueRecurringRules(recurringRules);
    final expenseDescriptions = thisWeekExpenses.map((e) => e.description.toLowerCase()).toSet();

    for (final rule in dueRecurring) {
      final isFound = expenseDescriptions.any(
        (desc) => desc.contains(rule.name.toLowerCase()) || desc.contains(rule.merchant.toLowerCase()),
      );

      if (!isFound) {
        insights.add(
          SpendInsight(
            id: 'recurring_variance_${rule.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Missing Recurring Payment',
            description: 'Expected "${rule.name}" payment not found this week.',
            severity: InsightSeverity.warning,
            type: InsightType.recurringVariance,
            actionLabel: 'Add Expense',
            actionRoute: '/expenses/add',
            generatedAt: DateTime.now(),
          ),
        );
      }
    }

    // Rule 5: Fee Impact (M-Pesa fees >5% of transaction)
    final highFeeExpenses = thisWeekExpenses
        .where((e) => e.fee != null && e.fee! > 0 && e.amount > 0)
        .where((e) => (e.fee! / e.amount) > 0.05)
        .toList();

    if (highFeeExpenses.isNotEmpty) {
      final totalFees = highFeeExpenses.fold<double>(0, (sum, e) => sum + (e.fee ?? 0));
      final avgFeePercent = (totalFees / _sumExpenseAmount(highFeeExpenses)) * 100;

      insights.add(
        SpendInsight(
          id: 'fee_impact_${DateTime.now().millisecondsSinceEpoch}',
          title: 'High Transaction Fees',
          description:
              'Your M-Pesa fees average ${avgFeePercent.toStringAsFixed(1)}% on high-fee transactions.',
          severity: InsightSeverity.info,
          type: InsightType.feeImpact,
          actionLabel: 'View Fees',
          actionRoute: '/analytics/fees',
          generatedAt: DateTime.now(),
        ),
      );
    }

    // Sort by severity (alerts first, then warnings, then info)
    insights.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return insights;
  }

  /// Sum all expense amounts.
  double _sumExpenseAmount(List<Expense> expenses) {
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Aggregate expenses by merchant.
  Map<String, double> _aggregateByMerchant(List<Expense> expenses) {
    final result = <String, double>{};
    for (final expense in expenses) {
      result[expense.merchant] = (result[expense.merchant] ?? 0.0) + expense.amount;
    }
    return result;
  }

  /// Get recurring rules that are due this week.
  List<RecurringRule> _getDueRecurringRules(List<RecurringRule> rules) {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));

    return rules.where((rule) {
      if (!rule.isActive) return false;
      final nextRun = rule.nextRunAt;
      return nextRun.isAfter(weekAgo) && nextRun.isBefore(now);
    }).toList();
  }
}
