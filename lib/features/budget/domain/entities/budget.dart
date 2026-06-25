/// Budget entity for spending insights generation.
class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.period,
    required this.isActive,
  });

  final String id;
  final String name;
  final double amount;
  final String period;
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          amount == other.amount &&
          period == other.period &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(id, name, amount, period, isActive);
}
