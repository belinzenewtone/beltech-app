/// Recurring rule for insights generation and notifications.
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.name,
    required this.merchant,
    required this.nextRunAt,
    required this.isActive,
  });

  final String id;
  final String name;
  final String merchant;
  final DateTime nextRunAt;
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          merchant == other.merchant &&
          nextRunAt == other.nextRunAt &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(id, name, merchant, nextRunAt, isActive);
}
