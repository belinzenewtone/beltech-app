import 'package:beltech/features/expenses/data/services/import_health_worker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ImportHealthWorker worker;

  setUp(() {
    worker = const ImportHealthWorker();
  });

  group('ImportHealthWorker', () {
    test('reports healthy when confidence is high and quarantine low', () {
      final report = worker.analyzeHealth(
        quarantineQueueDepth: 2,
        totalImportsToday: 20,
        confidenceScores: [0.9, 0.85, 0.88, 0.92, 0.80],
      );

      expect(report.isHealthy, isTrue);
      expect(report.status, equals('Healthy'));
      expect(report.quarantinePercentage, lessThan(20));
      expect(report.averageConfidence, greaterThan(0.80));
    });

    test('reports degraded when quarantine exceeds 30%', () {
      final report = worker.analyzeHealth(
        quarantineQueueDepth: 8,
        totalImportsToday: 20,
        confidenceScores: [0.6, 0.5, 0.4, 0.55, 0.45],
      );

      expect(report.isHealthy, isFalse);
      expect(report.status, equals('Degraded'));
      expect(report.quarantinePercentage, greaterThan(30));
      expect(report.alert, isNotNull);
    });

    test('generates alert for critical quarantine depth', () {
      final report = worker.analyzeHealth(
        quarantineQueueDepth: 15,
        totalImportsToday: 20,
        confidenceScores: [0.3, 0.25, 0.2, 0.35, 0.3],
      );

      expect(report.alert, isNotNull);
      expect(report.quarantineQueueDepth, equals(15));
    });

    test('handles empty confidence scores', () {
      final report = worker.analyzeHealth(
        quarantineQueueDepth: 0,
        totalImportsToday: 0,
        confidenceScores: [],
      );

      expect(report.averageConfidence, equals(0.0));
      expect(report.quarantinePercentage, equals(0.0));
    });

    test('counts confidence levels correctly', () {
      final report = worker.analyzeHealth(
        quarantineQueueDepth: 5,
        totalImportsToday: 10,
        confidenceScores: [
          0.95, 0.80, 0.75, // High
          0.70, 0.60, 0.50, // Medium
          0.40, 0.30, 0.20, // Low
          0.15,
        ],
      );

      expect(report.highConfidenceCount, equals(3));
      expect(report.mediumConfidenceCount, equals(3));
      expect(report.lowConfidenceCount, equals(4));
    });

    test('exposes all generated alerts', () {
      final report = worker.analyzeHealth(
        quarantineQueueDepth: 15,
        totalImportsToday: 20,
        confidenceScores: [0.3, 0.25, 0.2, 0.35, 0.3],
      );

      expect(report.alerts, isNotEmpty);
      expect(report.alert, equals(report.alerts.first));
      expect(
        report.alerts.any((a) => a.contains('Critical')),
        isTrue,
      );
    });

    test('flags anomaly when no high-confidence imports exist', () {
      final report = worker.analyzeHealth(
        quarantineQueueDepth: 2,
        totalImportsToday: 10,
        confidenceScores: [0.4, 0.35, 0.45, 0.3],
      );

      expect(
        report.alerts.any(
          (a) => a.toLowerCase().contains('no high-confidence'),
        ),
        isTrue,
      );
    });
  });
}
