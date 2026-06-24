class BudgetCategoryItem {
  const BudgetCategoryItem({
    required this.category,
    required this.monthlyLimitKes,
    required this.spentKes,
  });

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetCategoryItem &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          monthlyLimitKes == other.monthlyLimitKes &&
          spentKes == other.spentKes;

  @override
  int get hashCode => Object.hash(category, monthlyLimitKes, spentKes);
}

class BudgetSnapshot {
  const BudgetSnapshot({required this.month, required this.items});

  final DateTime month;
  final List<BudgetCategoryItem> items;

  double get totalLimitKes =>
      items.fold<double>(0, (sum, item) => sum + item.monthlyLimitKes);

  double get totalSpentKes =>
      items.fold<double>(0, (sum, item) => sum + item.spentKes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetSnapshot &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          _listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(month, Object.hashAll(items));
}

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
