class IncomeTrendPoint {
  const IncomeTrendPoint({required this.label, required this.incomeKes});

  final String label;
  final double incomeKes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeTrendPoint &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          incomeKes == other.incomeKes;

  @override
  int get hashCode => Object.hash(label, incomeKes);
}

class IncomeOverview {
  const IncomeOverview({
    required this.totalIncomeKes,
    required this.currentMonthIncomeKes,
    required this.currentMonthExpenseKes,
    required this.netCashflowKes,
    required this.trend,
  });

  final double totalIncomeKes;
  final double currentMonthIncomeKes;
  final double currentMonthExpenseKes;
  final double netCashflowKes;
  final List<IncomeTrendPoint> trend;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeOverview &&
          runtimeType == other.runtimeType &&
          totalIncomeKes == other.totalIncomeKes &&
          currentMonthIncomeKes == other.currentMonthIncomeKes &&
          currentMonthExpenseKes == other.currentMonthExpenseKes &&
          netCashflowKes == other.netCashflowKes &&
          _listEquals(trend, other.trend);

  @override
  int get hashCode => Object.hash(
    totalIncomeKes,
    currentMonthIncomeKes,
    currentMonthExpenseKes,
    netCashflowKes,
    Object.hashAll(trend),
  );
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
