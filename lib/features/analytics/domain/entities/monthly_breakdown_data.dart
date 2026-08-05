/// Per-month breakdown data for the Insights tab.
///
/// Each card shows month label, delta, total, tx count, and
/// expands to reveal top-5 category bars.

class MonthlyBreakdownData {
  const MonthlyBreakdownData({
    required this.periodKey,
    required this.monthLabel,
    required this.year,
    required this.month,
    required this.totalKes,
    required this.previousMonthTotalKes,
    required this.txCount,
    required this.topCategories,
  });

  final String periodKey;
  final String monthLabel;
  final int year;
  final int month;
  final double totalKes;
  final double previousMonthTotalKes;
  final int txCount;

  /// Top 5 categories by spend in this month, sorted descending.
  final List<MonthlyBreakdownCategory> topCategories;

  double? get monthOverMonthPct {
    if (previousMonthTotalKes <= 0) return null;
    return ((totalKes - previousMonthTotalKes) / previousMonthTotalKes) * 100;
  }
}

class MonthlyBreakdownCategory {
  const MonthlyBreakdownCategory({
    required this.category,
    required this.totalKes,
  });

  final String category;
  final double totalKes;
}
