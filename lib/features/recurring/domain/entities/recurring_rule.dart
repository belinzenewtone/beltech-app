/// Frequency enum for recurring rules.
enum RecurringFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  annually,
}

/// Recurring rule for insights generation and notifications.
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.name,
    required this.merchant,
    required this.nextRunAt,
    required this.isActive,
    this.frequency = RecurringFrequency.monthly,
    this.category,
    this.estimatedAmount,
    this.estimatedFee,
  });

  final String id;
  final String name;
  final String merchant;
  final DateTime nextRunAt;
  final bool isActive;
  final RecurringFrequency frequency;
  final String? category;
  final double? estimatedAmount;
  final double? estimatedFee;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          merchant == other.merchant &&
          nextRunAt == other.nextRunAt &&
          isActive == other.isActive &&
          frequency == other.frequency &&
          category == other.category &&
          estimatedAmount == other.estimatedAmount &&
          estimatedFee == other.estimatedFee;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    merchant,
    nextRunAt,
    isActive,
    frequency,
    category,
    estimatedAmount,
    estimatedFee,
  );
}
