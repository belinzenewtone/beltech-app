class ExpenseReviewItem {
  const ExpenseReviewItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amountKes,
    required this.occurredAt,
    required this.confidence,
    required this.rawMessage,
  });

  final int id;
  final String title;
  final String category;
  final double amountKes;
  final DateTime occurredAt;
  final double confidence;
  final String rawMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseReviewItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          category == other.category &&
          amountKes == other.amountKes &&
          occurredAt == other.occurredAt &&
          confidence == other.confidence &&
          rawMessage == other.rawMessage;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    category,
    amountKes,
    occurredAt,
    confidence,
    rawMessage,
  );
}

class ExpenseQuarantineItem {
  const ExpenseQuarantineItem({
    required this.id,
    required this.reason,
    required this.confidence,
    required this.rawMessage,
    required this.createdAt,
  });

  final int id;
  final String reason;
  final double confidence;
  final String rawMessage;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseQuarantineItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reason == other.reason &&
          confidence == other.confidence &&
          rawMessage == other.rawMessage &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, reason, confidence, rawMessage, createdAt);
}

class ExpenseImportMetrics {
  const ExpenseImportMetrics({
    required this.reviewQueueCount,
    required this.quarantineCount,
    required this.retryQueueCount,
    required this.failedQueueCount,
  });

  final int reviewQueueCount;
  final int quarantineCount;
  final int retryQueueCount;
  final int failedQueueCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseImportMetrics &&
          runtimeType == other.runtimeType &&
          reviewQueueCount == other.reviewQueueCount &&
          quarantineCount == other.quarantineCount &&
          retryQueueCount == other.retryQueueCount &&
          failedQueueCount == other.failedQueueCount;

  @override
  int get hashCode => Object.hash(
    reviewQueueCount,
    quarantineCount,
    retryQueueCount,
    failedQueueCount,
  );
}
