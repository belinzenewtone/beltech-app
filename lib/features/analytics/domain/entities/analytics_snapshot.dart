// Domain entities for the Analytics feature.
// Matches the Kotlin InsightsViewModel / AnalyticsData models 1-to-1.

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum AnalyticsPeriod { week, month }

// ─────────────────────────────────────────────────────────────────────────────
// Value types
// ─────────────────────────────────────────────────────────────────────────────

/// A single time-series data point (label + amount).
class AnalyticsPoint {
  const AnalyticsPoint({required this.label, required this.amountKes});

  final String label;
  final double amountKes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsPoint &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          amountKes == other.amountKes;

  @override
  int get hashCode => Object.hash(label, amountKes);
}

/// One calendar month in the 6-month rolling history.
class MonthlyTotalPoint {
  const MonthlyTotalPoint({
    required this.periodKey,
    required this.monthLabel,
    required this.totalKes,
    required this.year,
    required this.month,
  });

  /// "2025-07" format.
  final String periodKey;

  /// Short label, e.g. "Jul".
  final String monthLabel;
  final double totalKes;
  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyTotalPoint &&
          runtimeType == other.runtimeType &&
          periodKey == other.periodKey &&
          totalKes == other.totalKes;

  @override
  int get hashCode => Object.hash(periodKey, totalKes);
}

/// Per-category breakdown with 8-week sparkline and top merchant.
class AnalyticsCategoryShare {
  const AnalyticsCategoryShare({
    required this.category,
    required this.totalKes,
    required this.percentage,
    this.topMerchant,
    this.weeklySparkline = const [],
  });

  final String category;
  final double totalKes;

  /// 0–100 percentage of period spend.
  final double percentage;

  /// Most-visited merchant within this category (by tx count).
  final String? topMerchant;

  /// Last 8 rolling weeks of spend, oldest→newest (index 0 = 7 weeks ago).
  final List<double> weeklySparkline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsCategoryShare &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          totalKes == other.totalKes &&
          percentage == other.percentage;

  @override
  int get hashCode => Object.hash(category, totalKes, percentage);
}

/// Per-merchant spend share.
class AnalyticsMerchantShare {
  const AnalyticsMerchantShare({
    required this.merchant,
    required this.totalKes,
    required this.transactionCount,
  });

  final String merchant;
  final double totalKes;
  final int transactionCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsMerchantShare &&
          runtimeType == other.runtimeType &&
          merchant == other.merchant &&
          totalKes == other.totalKes;

  @override
  int get hashCode => Object.hash(merchant, totalKes);
}

// ─────────────────────────────────────────────────────────────────────────────
// Root aggregate
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.totalSpentThisPeriodKes,
    required this.totalIncomeThisPeriodKes,
    required this.previousPeriodTotalKes,
    required this.averageDailySpendingKes,
    required this.feesPaidKes,
    required this.totalTxCount,
    required this.microTxCount,
    required this.mediumTxCount,
    required this.largeTxCount,
    required this.totalTasksCompleted,
    required this.totalTasksPending,
    required this.totalEventsThisMonth,
    required this.productivityScore,
    required this.weeklySpending,
    required this.monthlySpending,
    required this.categoryBreakdown,
    required this.topMerchants,
    required this.monthlyHistory,
    this.postIncomeAvgDailySpendKes,
    this.otherDaysAvgDailySpendKes,
  });

  // ── Period totals ────────────────────────────────────────────────────────
  final double totalSpentThisPeriodKes;
  final double totalIncomeThisPeriodKes;
  final double previousPeriodTotalKes;
  final double averageDailySpendingKes;
  final double feesPaidKes;

  // ── Transaction size breakdown ───────────────────────────────────────────
  /// Total number of expense transactions in the period.
  final int totalTxCount;

  /// Transactions < KES 500.
  final int microTxCount;

  /// Transactions KES 500–1 999.
  final int mediumTxCount;

  /// Transactions ≥ KES 2 000.
  final int largeTxCount;

  // ── Productivity ─────────────────────────────────────────────────────────
  final int totalTasksCompleted;
  final int totalTasksPending;
  final int totalEventsThisMonth;
  final double productivityScore;

  // ── Chart series ─────────────────────────────────────────────────────────
  final List<AnalyticsPoint> weeklySpending;
  final List<AnalyticsPoint> monthlySpending;

  // ── Breakdowns ───────────────────────────────────────────────────────────
  final List<AnalyticsCategoryShare> categoryBreakdown;
  final List<AnalyticsMerchantShare> topMerchants;

  // ── 6-month rolling history (Insights tab) ───────────────────────────────
  final List<MonthlyTotalPoint> monthlyHistory;

  // ── Payday pulse (Insights tab) ──────────────────────────────────────────
  /// Average daily spend in the 7 days after any income receipt.
  final double? postIncomeAvgDailySpendKes;

  /// Average daily spend on days outside post-income windows.
  final double? otherDaysAvgDailySpendKes;

  // ── Backward-compat alias ────────────────────────────────────────────────
  double get totalSpentThisMonthKes => totalSpentThisPeriodKes;

  // ── Derived helpers ──────────────────────────────────────────────────────
  double get netKes => totalIncomeThisPeriodKes - totalSpentThisPeriodKes;

  double get avgTransactionKes =>
      totalTxCount > 0 ? totalSpentThisPeriodKes / totalTxCount : 0;

  /// Positive = spending went up vs previous period. Null if no prior data.
  double? get periodChangePercent {
    if (previousPeriodTotalKes <= 0) return null;
    return ((totalSpentThisPeriodKes - previousPeriodTotalKes) /
            previousPeriodTotalKes) *
        100;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSnapshot &&
          runtimeType == other.runtimeType &&
          totalSpentThisPeriodKes == other.totalSpentThisPeriodKes &&
          totalIncomeThisPeriodKes == other.totalIncomeThisPeriodKes &&
          previousPeriodTotalKes == other.previousPeriodTotalKes &&
          averageDailySpendingKes == other.averageDailySpendingKes &&
          totalTasksCompleted == other.totalTasksCompleted &&
          totalTasksPending == other.totalTasksPending &&
          totalEventsThisMonth == other.totalEventsThisMonth &&
          productivityScore == other.productivityScore &&
          _listEquals(weeklySpending, other.weeklySpending) &&
          _listEquals(monthlySpending, other.monthlySpending) &&
          _listEquals(categoryBreakdown, other.categoryBreakdown) &&
          _listEquals(topMerchants, other.topMerchants) &&
          _listEquals(monthlyHistory, other.monthlyHistory);

  @override
  int get hashCode => Object.hash(
        totalSpentThisPeriodKes,
        totalIncomeThisPeriodKes,
        previousPeriodTotalKes,
        averageDailySpendingKes,
        totalTasksCompleted,
        totalTasksPending,
        totalEventsThisMonth,
        productivityScore,
        Object.hashAll(weeklySpending),
        Object.hashAll(monthlySpending),
        Object.hashAll(categoryBreakdown),
        Object.hashAll(topMerchants),
        Object.hashAll(monthlyHistory),
      );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
