enum GlobalSearchKind { expense, income, task, event, budget, recurring, merchant }

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.kind,
    required this.primaryText,
    required this.secondaryText,
    required this.trailingText,
    this.recordId,
    this.recordDate,
  });

  final GlobalSearchKind kind;
  final String primaryText;
  final String secondaryText;
  final String trailingText;
  final int? recordId;
  final DateTime? recordDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlobalSearchResult &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          primaryText == other.primaryText &&
          secondaryText == other.secondaryText &&
          trailingText == other.trailingText &&
          recordId == other.recordId &&
          recordDate == other.recordDate;

  @override
  int get hashCode => Object.hash(
    kind,
    primaryText,
    secondaryText,
    trailingText,
    recordId,
    recordDate,
  );
}
