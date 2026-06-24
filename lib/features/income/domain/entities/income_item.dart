class IncomeItem {
  const IncomeItem({
    required this.id,
    required this.title,
    required this.amountKes,
    required this.receivedAt,
    required this.source,
  });

  final int id;
  final String title;
  final double amountKes;
  final DateTime receivedAt;
  final String source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          amountKes == other.amountKes &&
          receivedAt == other.receivedAt &&
          source == other.source;

  @override
  int get hashCode =>
      Object.hash(id, title, amountKes, receivedAt, source);
}
