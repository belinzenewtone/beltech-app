/// Core expense entity for domain logic and insights generation.
class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.description,
    required this.occurredAt,
    this.fee,
    this.category,
  });

  final String id;
  final double amount;
  final String merchant;
  final String description;
  final DateTime occurredAt;
  final double? fee;
  final String? category;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          merchant == other.merchant &&
          description == other.description &&
          occurredAt == other.occurredAt &&
          fee == other.fee &&
          category == other.category;

  @override
  int get hashCode =>
      Object.hash(id, amount, merchant, description, occurredAt, fee, category);
}
