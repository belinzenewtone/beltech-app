class BudgetTargetProgress {
  const BudgetTargetProgress({
    required this.id,
    required this.category,
    required this.monthlyLimitKes,
    required this.spentKes,
  });

  final int id;
  final String category;
  final double monthlyLimitKes;
  final double spentKes;

  double get remainingKes => monthlyLimitKes - spentKes;

  double get usageRatio {
    if (monthlyLimitKes <= 0) {
      return 0;
    }
    final ratio = spentKes / monthlyLimitKes;
    if (ratio < 0) {
      return 0;
    }
    if (ratio > 1) {
      return 1;
    }
    return ratio;
  }

  bool get isNearLimit => usageRatio >= 0.8 && spentKes <= monthlyLimitKes;

  bool get isOverLimit => spentKes > monthlyLimitKes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetTargetProgress &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          category == other.category &&
          monthlyLimitKes == other.monthlyLimitKes &&
          spentKes == other.spentKes;

  @override
  int get hashCode => Object.hash(id, category, monthlyLimitKes, spentKes);
}
