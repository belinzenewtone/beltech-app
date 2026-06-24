enum InsightKind {
  spending,
  savings,
  taskCompletion,
  anomaly,
  health,
  cashFlow,
  budget,
  general,
}

enum InsightTone { positive, neutral, warning, info }

class InsightCard {
  const InsightCard({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.tone,
    required this.confidence,
    required this.generatedAt,
    this.actionRoute,
  });

  final String id;
  final InsightKind kind;
  final String title;
  final String body;
  final InsightTone tone;
  final double confidence;
  final DateTime generatedAt;
  final String? actionRoute;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightCard &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
