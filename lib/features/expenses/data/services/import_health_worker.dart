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
    final alerts = _generateAlerts(
      quarantinePercent: quarantinePercent,
      avgConfidence: avgConfidence,
      queueDepth: quarantineQueueDepth,
      highConfidenceCount: highConfidence,
      totalImportsToday: totalImportsToday,
    );

    return ImportHealthReport(
      isHealthy: isHealthy,
      quarantineQueueDepth: quarantineQueueDepth,
      quarantinePercentage: quarantinePercent,
      averageConfidence: avgConfidence,
      highConfidenceCount: highConfidence,
      mediumConfidenceCount: mediumConfidence,
      lowConfidenceCount: lowConfidence,
      alert: alerts.isNotEmpty ? alerts.first : null,
      alerts: alerts,
    );
  }

  /// Generate health alert messages if needed.
  List<String> _generateAlerts({
    required double quarantinePercent,
    required double avgConfidence,
    required int queueDepth,
    required int highConfidenceCount,
    required int totalImportsToday,
  }) {
    final alerts = <String>[];
    if (quarantinePercent > 50) {
      alerts.add(
        'Critical: Over 50% of imports require review (quarantine depth: $queueDepth)',
      );
    } else if (quarantinePercent > 30) {
      alerts.add(
        'Warning: ${quarantinePercent.toStringAsFixed(0)}% of imports need review',
      );
    }
    if (avgConfidence < 0.50) {
      alerts.add(
        'Alert: Average confidence score is low (${avgConfidence.toStringAsFixed(2)})',
      );
    }
    if (totalImportsToday > 0 && highConfidenceCount == 0) {
      alerts.add('Anomaly: no high-confidence imports in the latest run.');
    }
    return alerts;
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
    this.alerts = const [],
  });

  final bool isHealthy;
  final int quarantineQueueDepth;
  final double quarantinePercentage;
  final double averageConfidence;
  final int highConfidenceCount;
  final int mediumConfidenceCount;
  final int lowConfidenceCount;

  /// The most severe alert, if any. Kept for backward compatibility;
  /// consumers should prefer [alerts].
  final String? alert;

  /// All health alerts generated for this run.
  final List<String> alerts;

  String get status => isHealthy ? 'Healthy' : 'Degraded';
}
