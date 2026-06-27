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

/// A single day's import-quality snapshot, used for trend charts.
class DailyImportTrend {
  const DailyImportTrend({
    required this.date,
    required this.total,
    required this.quarantineCount,
    required this.averageConfidence,
  });

  final DateTime date;
  final int total;
  final int quarantineCount;
  final double averageConfidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyImportTrend &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          total == other.total &&
          quarantineCount == other.quarantineCount &&
          averageConfidence == other.averageConfidence;

  @override
  int get hashCode => Object.hash(date, total, quarantineCount, averageConfidence);
}

class ExpenseImportMetrics {
  const ExpenseImportMetrics({
    required this.reviewQueueCount,
    required this.quarantineCount,
    required this.retryQueueCount,
    required this.failedQueueCount,
    this.lastImportAt,
    this.lastMpesaCode,
    this.lastError,
    this.quarantineReasonBreakdown = const {},
    this.duplicateSkipCount = 0,
    this.dailyTrends = const [],
    this.alerts = const [],
  });

  final int reviewQueueCount;
  final int quarantineCount;
  final int retryQueueCount;
  final int failedQueueCount;

  /// When the most recently touched import-queue row was last updated.
  final DateTime? lastImportAt;

  /// The M-Pesa transaction code extracted from the most recent queue row,
  /// if one could be parsed.
  final String? lastMpesaCode;

  /// The last recorded import error, if any.
  final String? lastError;

  /// How many quarantined items exist for each quarantine reason.
  final Map<String, int> quarantineReasonBreakdown;

  /// How many messages were skipped because their source_hash already existed.
  final int duplicateSkipCount;

  /// Daily import-quality trend for the last 30 days.
  final List<DailyImportTrend> dailyTrends;

  /// Pre-computed anomaly alerts for the current import state.
  final List<String> alerts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseImportMetrics &&
          runtimeType == other.runtimeType &&
          reviewQueueCount == other.reviewQueueCount &&
          quarantineCount == other.quarantineCount &&
          retryQueueCount == other.retryQueueCount &&
          failedQueueCount == other.failedQueueCount &&
          lastImportAt == other.lastImportAt &&
          lastMpesaCode == other.lastMpesaCode &&
          lastError == other.lastError &&
          quarantineReasonBreakdown == other.quarantineReasonBreakdown &&
          duplicateSkipCount == other.duplicateSkipCount &&
          dailyTrends == other.dailyTrends &&
          alerts == other.alerts;

  @override
  int get hashCode => Object.hash(
    reviewQueueCount,
    quarantineCount,
    retryQueueCount,
    failedQueueCount,
    lastImportAt,
    lastMpesaCode,
    lastError,
    quarantineReasonBreakdown,
    duplicateSkipCount,
    dailyTrends,
    alerts,
  );
}
