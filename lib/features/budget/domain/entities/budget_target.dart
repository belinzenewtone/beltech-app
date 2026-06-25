class BudgetTarget {
  const BudgetTarget({
    required this.id,
    required this.category,
    required this.monthlyLimitKes,
  });

  final int id;
  final String category;
  final double monthlyLimitKes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetTarget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          category == other.category &&
          monthlyLimitKes == other.monthlyLimitKes;

  @override
  int get hashCode => Object.hash(id, category, monthlyLimitKes);
}
