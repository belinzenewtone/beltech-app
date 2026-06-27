import 'dart:math';

import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';

/// Detects recurring spending/income patterns from transaction history and
/// returns suggested recurring templates.
class RecurringSuggestionService {
  const RecurringSuggestionService();

  /// Analyse transactions and emit candidate recurring templates.
  ///
  /// A candidate is produced when the same title occurs at least [minOccurrences]
  /// times with similar amounts and the gaps between occurrences cluster around
  /// a weekly or monthly cadence.
  List<SuggestedRecurringTemplate> detectSuggestions(
    List<ExpenseItem> transactions, {
    int minOccurrences = 2,
  }) {
    if (transactions.length < minOccurrences) return const [];

    final byTitle = <String, List<ExpenseItem>>{};
    for (final tx in transactions) {
      final key = tx.title.toLowerCase().trim();
      if (key.isEmpty) continue;
      byTitle.putIfAbsent(key, () => []).add(tx);
    }

    final suggestions = <SuggestedRecurringTemplate>[];
    for (final entry in byTitle.entries) {
      final group = entry.value
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      if (group.length < minOccurrences) continue;

      final cadence = _detectCadence(group);
      if (cadence == null) continue;

      final amount = _medianAmount(group);
      final latest = group.last;
      final nextRunAt = _projectNextRun(group, cadence);
      if (nextRunAt == null) continue;

      suggestions.add(
        SuggestedRecurringTemplate(
          title: latest.title,
          category: _dominantCategory(group),
          amountKes: amount,
          cadence: cadence,
          nextRunAt: nextRunAt,
          sampleCount: group.length,
        ),
      );
    }

    // Only keep the strongest suggestion per title.
    final byTitleMap = <String, SuggestedRecurringTemplate>{};
    for (final s in suggestions) {
      final key = s.title.toLowerCase().trim();
      final existing = byTitleMap[key];
      if (existing == null || s.sampleCount > existing.sampleCount) {
        byTitleMap[key] = s;
      }
    }
    return byTitleMap.values.toList()
      ..sort((a, b) => b.sampleCount.compareTo(a.sampleCount));
  }

  RecurringCadence? _detectCadence(List<ExpenseItem> group) {
    if (group.length < 2) return null;
    final gaps = <int>[];
    for (var i = 1; i < group.length; i++) {
      gaps.add(group[i].occurredAt.difference(group[i - 1].occurredAt).inDays);
    }
    if (gaps.isEmpty) return null;

    final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
    final variance = gaps
            .map((g) => (g - avgGap) * (g - avgGap))
            .reduce((a, b) => a + b) /
        gaps.length;
    final stdDev = variance <= 0 ? 0.0 : sqrt(variance);

    // Tight clustering around 7 or 30 days.
    if ((avgGap - 7).abs() <= 2 && stdDev <= 3) {
      return RecurringCadence.weekly;
    }
    if ((avgGap - 30).abs() <= 5 && stdDev <= 7) {
      return RecurringCadence.monthly;
    }
    if ((avgGap - 1).abs() <= 0.5 && stdDev <= 1) {
      return RecurringCadence.daily;
    }
    return null;
  }

  double _medianAmount(List<ExpenseItem> group) {
    final amounts = group.map((t) => t.amountKes).toList()..sort();
    final mid = amounts.length ~/ 2;
    if (amounts.length.isOdd) return amounts[mid];
    return (amounts[mid - 1] + amounts[mid]) / 2;
  }

  String _dominantCategory(List<ExpenseItem> group) {
    final counts = <String, int>{};
    for (final t in group) {
      counts[t.category] = (counts[t.category] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  DateTime? _projectNextRun(List<ExpenseItem> group, RecurringCadence cadence) {
    if (group.isEmpty) return null;
    final latest = group.last.occurredAt;
    return switch (cadence) {
      RecurringCadence.daily => latest.add(const Duration(days: 1)),
      RecurringCadence.weekly => latest.add(const Duration(days: 7)),
      RecurringCadence.monthly => _addMonths(latest, 1),
    };
  }

  DateTime _addMonths(DateTime value, int months) {
    var year = value.year;
    var month = value.month + months;
    while (month > 12) {
      month -= 12;
      year++;
    }
    final day = value.day;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day, value.hour,
        value.minute,);
  }
}

/// A recurring template detected from historical transactions.
class SuggestedRecurringTemplate {
  const SuggestedRecurringTemplate({
    required this.title,
    required this.category,
    required this.amountKes,
    required this.cadence,
    required this.nextRunAt,
    required this.sampleCount,
  });

  final String title;
  final String category;
  final double amountKes;
  final RecurringCadence cadence;
  final DateTime nextRunAt;
  final int sampleCount;
}
