class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.totalSpentThisMonthKes,
    required this.averageDailySpendingKes,
    required this.totalTasksCompleted,
    required this.totalTasksPending,
    required this.totalEventsThisMonth,
    required this.productivityScore,
    required this.weeklySpending,
    required this.monthlySpending,
    required this.categoryBreakdown,
    required this.topMerchants,
  });

  final double totalSpentThisMonthKes;
  final double averageDailySpendingKes;
  final int totalTasksCompleted;
  final int totalTasksPending;
  final int totalEventsThisMonth;
  final double productivityScore;
  final List<AnalyticsPoint> weeklySpending;
  final List<AnalyticsPoint> monthlySpending;
  final List<AnalyticsCategoryShare> categoryBreakdown;
  final List<AnalyticsMerchantShare> topMerchants;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSnapshot &&
          runtimeType == other.runtimeType &&
          totalSpentThisMonthKes == other.totalSpentThisMonthKes &&
          averageDailySpendingKes == other.averageDailySpendingKes &&
          totalTasksCompleted == other.totalTasksCompleted &&
          totalTasksPending == other.totalTasksPending &&
          totalEventsThisMonth == other.totalEventsThisMonth &&
          productivityScore == other.productivityScore &&
          _listEquals(weeklySpending, other.weeklySpending) &&
          _listEquals(monthlySpending, other.monthlySpending) &&
          _listEquals(categoryBreakdown, other.categoryBreakdown) &&
          _listEquals(topMerchants, other.topMerchants);

  @override
  int get hashCode => Object.hash(
    totalSpentThisMonthKes,
    averageDailySpendingKes,
    totalTasksCompleted,
    totalTasksPending,
    totalEventsThisMonth,
    productivityScore,
    Object.hashAll(weeklySpending),
    Object.hashAll(monthlySpending),
    Object.hashAll(categoryBreakdown),
    Object.hashAll(topMerchants),
  );
}

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

class AnalyticsCategoryShare {
  const AnalyticsCategoryShare({
    required this.category,
    required this.totalKes,
    required this.percentage,
  });

  final String category;
  final double totalKes;
  final double percentage;

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
          totalKes == other.totalKes &&
          transactionCount == other.transactionCount;

  @override
  int get hashCode => Object.hash(merchant, totalKes, transactionCount);
}

enum AnalyticsPeriod { week, month }

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
