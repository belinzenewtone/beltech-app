import 'dart:math';

import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';

/// Detects anomalies in financial and productivity data.
/// Inspired by Kotlin app's AnomalyDetector.
class AnomalyDetector {
  const AnomalyDetector();

  List<Anomaly> detect(List<RecentTransaction> transactions) {
    final anomalies = <Anomaly>[];
    anomalies.addAll(_detectDuplicates(transactions));
    anomalies.addAll(_detectDailySurges(transactions));
    anomalies.addAll(_detectCategorySpikes(transactions));
    anomalies.addAll(_detectUnusualAmounts(transactions));
    return anomalies;
  }

  List<Anomaly> _detectDuplicates(List<RecentTransaction> txs) {
    final anomalies = <Anomaly>[];
    final seen = <String, RecentTransaction>{};
    for (final tx in txs) {
      final key =
          '${tx.title.trim().toLowerCase()}_${tx.amount.toStringAsFixed(2)}_${tx.date.day}';
      if (seen.containsKey(key)) {
        anomalies.add(
          Anomaly(
            type: AnomalyType.duplicate,
            description:
                'Duplicate transaction: "${tx.title}" for ${tx.amount.toStringAsFixed(0)}',
            severity: AnomalySeverity.medium,
          ),
        );
      } else {
        seen[key] = tx;
      }
    }
    return anomalies;
  }

  List<Anomaly> _detectDailySurges(List<RecentTransaction> txs) {
    if (txs.length < 3) return [];
    final dailyTotals = <int, double>{};
    for (final tx in txs.where((t) => t.type == 'expense')) {
      final day =
          DateTime(
            tx.date.year,
            tx.date.month,
            tx.date.day,
          ).millisecondsSinceEpoch ~/
          86400000;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + tx.amount;
    }
    if (dailyTotals.length < 3) return [];
    final values = dailyTotals.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    final stdDev = sqrt(variance);
    final threshold = mean + 2 * stdDev;

    return dailyTotals.entries
        .where((e) => e.value > threshold && e.value > mean * 1.5)
        .map(
          (e) => Anomaly(
            type: AnomalyType.dailySurge,
            description:
                'Unusually high spending day: ${e.value.toStringAsFixed(0)}',
            severity: e.value > threshold * 1.5
                ? AnomalySeverity.high
                : AnomalySeverity.medium,
          ),
        )
        .toList();
  }

  List<Anomaly> _detectCategorySpikes(List<RecentTransaction> txs) {
    if (txs.length < 5) return [];
    final byCategory = <String, List<double>>{};
    for (final tx in txs.where((t) => t.type == 'expense')) {
      byCategory
          .putIfAbsent(tx.category.toLowerCase(), () => [])
          .add(tx.amount);
    }
    final anomalies = <Anomaly>[];
    for (final entry in byCategory.entries) {
      final amounts = entry.value;
      if (amounts.length < 3) continue;
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final latest = amounts.last;
      if (latest > mean * 3 && latest > 1000) {
        anomalies.add(
          Anomaly(
            type: AnomalyType.categorySpike,
            description:
                'Spike in ${entry.key}: ${latest.toStringAsFixed(0)} vs avg ${mean.toStringAsFixed(0)}',
            severity: latest > mean * 5
                ? AnomalySeverity.high
                : AnomalySeverity.medium,
          ),
        );
      }
    }
    return anomalies;
  }

  List<Anomaly> _detectUnusualAmounts(List<RecentTransaction> txs) {
    if (txs.isEmpty) return [];
    final amounts = txs
        .where((t) => t.type == 'expense')
        .map((t) => t.amount)
        .toList();
    if (amounts.length < 3) return [];
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final variance =
        amounts.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        amounts.length;
    final stdDev = sqrt(variance);
    final threshold = mean + 2.5 * stdDev;

    return txs
        .where(
          (t) =>
              t.type == 'expense' &&
              t.amount > threshold &&
              t.amount > mean * 2,
        )
        .map(
          (t) => Anomaly(
            type: AnomalyType.unusualAmount,
            description:
                'Unusual amount: "${t.title}" ${t.amount.toStringAsFixed(0)}',
            severity: t.amount > threshold * 1.5
                ? AnomalySeverity.high
                : AnomalySeverity.medium,
          ),
        )
        .toList();
  }
}
