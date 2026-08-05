// Monthly Wrapped domain entity — mirrors Kotlin MonthlyWrappedUiState.

/// A single category row in the Monthly Wrapped top-5 list.
class WrappedCategoryRow {
  const WrappedCategoryRow({
    required this.category,
    required this.totalKes,
    required this.percentage,
    required this.rank,
  });

  final String category;
  final double totalKes;

  /// 0–100 percentage of month spend.
  final double percentage;

  /// 1-based rank (1 = highest spend).
  final int rank;
}

/// Full data model for one month's wrapped summary.
class MonthlyWrappedData {
  const MonthlyWrappedData({
    required this.year,
    required this.month,
    required this.totalSpentKes,
    required this.prevMonthTotalKes,
    required this.txCount,
    required this.topCategories,
    this.biggestTxMerchant,
    required this.biggestTxAmount,
    this.topMerchant,
    required this.topMerchantCount,
    required this.feesPaidKes,
    required this.activeDays,
    required this.daysInMonth,
    required this.incomeTotalKes,
    required this.fulizaUsedCount,
    required this.fulizaTotal,
  });

  final int year;
  final int month;

  final double totalSpentKes;
  final double prevMonthTotalKes;
  final int txCount;

  /// Top 5 categories by spend (rank 1–5).
  final List<WrappedCategoryRow> topCategories;

  /// Merchant of the single largest transaction.
  final String? biggestTxMerchant;
  final double biggestTxAmount;

  /// Most-visited merchant (by transaction count).
  final String? topMerchant;
  final int topMerchantCount;

  final double feesPaidKes;

  /// Number of distinct calendar days that had at least one transaction.
  final int activeDays;
  final int daysInMonth;

  final double incomeTotalKes;
  final int fulizaUsedCount;
  final double fulizaTotal;

  // ── Derived helpers ───────────────────────────────────────────────────────

  bool get hasData => totalSpentKes > 0 || txCount > 0;

  /// Positive = spent more than previous month (percentage points).
  double? get monthOverMonthPct {
    if (prevMonthTotalKes <= 0) return null;
    return ((totalSpentKes - prevMonthTotalKes) / prevMonthTotalKes) * 100;
  }

  double get savedKes => incomeTotalKes - totalSpentKes;

  bool get isOverBudget =>
      incomeTotalKes > 0 && totalSpentKes > incomeTotalKes;
}
