import 'package:beltech/features/assistant/domain/ai_engine/anomaly_detector.dart';
import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const detector = AnomalyDetector();

  group('AnomalyDetector', () {
    test('detects duplicate transactions', () {
      final txs = [
        RecentTransaction(
          title: 'Coffee',
          category: 'Food',
          amount: 500,
          date: DateTime(2024, 1, 1),
          type: 'expense',
        ),
        RecentTransaction(
          title: 'Coffee',
          category: 'Food',
          amount: 500,
          date: DateTime(2024, 1, 1),
          type: 'expense',
        ),
      ];
      final anomalies = detector.detect(txs);
      expect(anomalies.length, 1);
      expect(anomalies.first.type, AnomalyType.duplicate);
    });

    test('detects daily spending surges', () {
      final txs = [
        for (int i = 0; i < 5; i++)
          RecentTransaction(
            title: 'Item',
            category: 'Misc',
            amount: 100,
            date: DateTime(2024, 1, i + 1),
            type: 'expense',
          ),
        RecentTransaction(
          title: 'Big',
          category: 'Misc',
          amount: 10000,
          date: DateTime(2024, 1, 6),
          type: 'expense',
        ),
      ];
      final anomalies = detector.detect(txs);
      final surge = anomalies.where((a) => a.type == AnomalyType.dailySurge);
      expect(surge.isNotEmpty, true);
    });

    test('detects category spikes', () {
      final txs = [
        for (int i = 0; i < 5; i++)
          RecentTransaction(
            title: 'Snack',
            category: 'Food',
            amount: 200,
            date: DateTime(2024, 1, i + 1),
            type: 'expense',
          ),
        RecentTransaction(
          title: 'Dinner',
          category: 'Food',
          amount: 5000,
          date: DateTime(2024, 1, 6),
          type: 'expense',
        ),
      ];
      final anomalies = detector.detect(txs);
      final spike = anomalies.where((a) => a.type == AnomalyType.categorySpike);
      expect(spike.isNotEmpty, true);
    });

    test('detects unusual amounts', () {
      final txs = [
        for (int i = 0; i < 5; i++)
          RecentTransaction(
            title: 'Small',
            category: 'X',
            amount: 100,
            date: DateTime(2024, 1, i + 1),
            type: 'expense',
          ),
        RecentTransaction(
          title: 'Huge',
          category: 'X',
          amount: 10000,
          date: DateTime(2024, 1, 6),
          type: 'expense',
        ),
      ];
      final anomalies = detector.detect(txs);
      final unusual = anomalies.where(
        (a) => a.type == AnomalyType.unusualAmount,
      );
      expect(unusual.isNotEmpty, true);
    });

    test('returns empty when no anomalies', () {
      final txs = [
        for (int i = 0; i < 3; i++)
          RecentTransaction(
            title: 'Norm',
            category: 'X',
            amount: 500,
            date: DateTime(2024, 1, i + 1),
            type: 'expense',
          ),
      ];
      final anomalies = detector.detect(txs);
      expect(anomalies, isEmpty);
    });
  });
}
