/// Monitor and report on SMS import quality and health.
/// Tracks quarantine queue depth, confidence distribution, and anomalies.
class ImportHealthWorker {
  const ImportHealthWorker();

  /// Analyze import health metrics.
  ImportHealthReport analyzeHealth({
    required int quarantineQueueDepth,
    required int totalImportsToday,
    required List<double> confidenceScores,
  }) {
    final highConfidence = confidenceScores.where((s) => s >= 0.75).length;
    final mediumConfidence = confidenceScores
        .where((s) => s >= 0.50 && s < 0.75)
        .length;
    final lowConfidence = confidenceScores.where((s) => s < 0.50).length;

    final avgConfidence = confidenceScores.isEmpty
        ? 0.0
        : confidenceScores.reduce((a, b) => a + b) / confidenceScores.length;

    final quarantinePercent = totalImportsToday == 0
        ? 0.0
        : (quarantineQueueDepth / totalImportsToday) * 100;

    final isHealthy = quarantinePercent < 20 && avgConfidence > 0.70;
    final alert = _generateAlert(
      quarantinePercent,
      avgConfidence,
      quarantineQueueDepth,
    );

    return ImportHealthReport(
      isHealthy: isHealthy,
      quarantineQueueDepth: quarantineQueueDepth,
      quarantinePercentage: quarantinePercent,
      averageConfidence: avgConfidence,
      highConfidenceCount: highConfidence,
      mediumConfidenceCount: mediumConfidence,
      lowConfidenceCount: lowConfidence,
      alert: alert,
    );
  }

  /// Generate health alert message if needed.
  String? _generateAlert(
    double quarantinePercent,
    double avgConfidence,
    int queueDepth,
  ) {
    if (quarantinePercent > 50) {
      return 'Critical: Over 50% of imports require review (quarantine depth: $queueDepth)';
    }
    if (quarantinePercent > 30) {
      return 'Warning: ${quarantinePercent.toStringAsFixed(0)}% of imports need review';
    }
    if (avgConfidence < 0.50) {
      return 'Alert: Average confidence score is low (${avgConfidence.toStringAsFixed(2)})';
    }
    return null;
  }
}

/// Report on import health metrics.
class ImportHealthReport {
  const ImportHealthReport({
    required this.isHealthy,
    required this.quarantineQueueDepth,
    required this.quarantinePercentage,
    required this.averageConfidence,
    required this.highConfidenceCount,
    required this.mediumConfidenceCount,
    required this.lowConfidenceCount,
    this.alert,
  });

  final bool isHealthy;
  final int quarantineQueueDepth;
  final double quarantinePercentage;
  final double averageConfidence;
  final int highConfidenceCount;
  final int mediumConfidenceCount;
  final int lowConfidenceCount;
  final String? alert;

  String get status => isHealthy ? 'Healthy' : 'Degraded';
}
