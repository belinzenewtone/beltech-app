class GoalItem {
  const GoalItem({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.color,
    required this.createdAt,
  });

  final int id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? color;
  final DateTime createdAt;

  double get progressPercent => targetAmount > 0 ? currentAmount / targetAmount : 0;
  bool get isAtRisk {
    if (deadline == null || targetAmount <= 0) return false;
    final total = deadline!.difference(createdAt).inDays;
    final elapsed = DateTime.now().difference(createdAt).inDays;
    final expectedProgress = total > 0 ? elapsed / total : 1;
    return progressPercent < expectedProgress * 0.6 && elapsed > total * 0.5;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount;

  @override
  int get hashCode => Object.hash(id, title, targetAmount, currentAmount);
}
