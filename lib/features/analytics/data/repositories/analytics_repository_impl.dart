import 'dart:async';

import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<AnalyticsSnapshot> watchSnapshot() {
    return Stream<AnalyticsSnapshot>.multi((controller) async {
      var emitting = false;

      Future<void> emitSnapshot() async {
        if (controller.isClosed || emitting) {
          return;
        }
        emitting = true;
        try {
          controller.add(await _loadSnapshot());
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        } finally {
          emitting = false;
        }
      }

      await emitSnapshot();
      final timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(emitSnapshot()),
      );
      controller.onCancel = timer.cancel;
    });
  }

  Future<AnalyticsSnapshot> _loadSnapshot() async {
    await _store.ensureInitialized();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final weekStart = _weekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final txRows = await _store.executor.runSelect(
      'SELECT amount, category, occurred_at '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'ORDER BY occurred_at ASC',
      [monthStart.millisecondsSinceEpoch, monthEnd.millisecondsSinceEpoch],
    );
    final weekRows = await _store.executor.runSelect(
      'SELECT amount, occurred_at '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'ORDER BY occurred_at ASC',
      [weekStart.millisecondsSinceEpoch, weekEnd.millisecondsSinceEpoch],
    );
    final taskRows = await _store.executor
        .runSelect('SELECT completed FROM tasks', const []);
    final eventCountRows = await _store.executor.runSelect(
      'SELECT COUNT(*) AS total FROM events '
      'WHERE start_at >= ? AND start_at < ?',
      [monthStart.millisecondsSinceEpoch, monthEnd.millisecondsSinceEpoch],
    );

    final monthTotal = txRows.fold<double>(
      0,
      (sum, row) => sum + _asDouble(row['amount']),
    );
    final elapsedDays = now.day <= 0 ? 1 : now.day;
    final averageDaily = monthTotal / elapsedDays;

    final completed =
        taskRows.where((row) => _asInt(row['completed']) == 1).length;
    final pending = taskRows.length - completed;
    final eventsThisMonth =
        eventCountRows.isEmpty ? 0 : _asInt(eventCountRows.first['total']);
    final productivity =
        _productivityScore(completed: completed, pending: pending);

    final weeklyMap = {
      for (final date in _weekDates(weekStart)) _dayShort(date): 0.0,
    };
    for (final row in weekRows) {
      final occurredAt =
          DateTime.fromMillisecondsSinceEpoch(_asInt(row['occurred_at']));
      final key = _dayShort(occurredAt);
      weeklyMap[key] = (weeklyMap[key] ?? 0) + _asDouble(row['amount']);
    }

    final monthDailyMap = {
      for (var day = 1;
          day <= monthEnd.subtract(const Duration(days: 1)).day;
          day++)
        '$day': 0.0,
    };
    final categoryTotals = <String, double>{};
    for (final row in txRows) {
      final amount = _asDouble(row['amount']);
      final occurredAt =
          DateTime.fromMillisecondsSinceEpoch(_asInt(row['occurred_at']));
      monthDailyMap['${occurredAt.day}'] =
          (monthDailyMap['${occurredAt.day}'] ?? 0) + amount;

      final category = '${row['category'] ?? 'Other'}';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    final categoryBreakdown = categoryTotals.entries
        .map(
          (entry) => AnalyticsCategoryShare(
            category: entry.key,
            totalKes: entry.value,
            percentage: monthTotal <= 0 ? 0 : (entry.value / monthTotal) * 100,
          ),
        )
        .toList()
      ..sort((a, b) => b.totalKes.compareTo(a.totalKes));

    return AnalyticsSnapshot(
      totalSpentThisMonthKes: monthTotal,
      averageDailySpendingKes: averageDaily,
      totalTasksCompleted: completed,
      totalTasksPending: pending,
      totalEventsThisMonth: eventsThisMonth,
      productivityScore: productivity,
      weeklySpending: weeklyMap.entries
          .map((entry) =>
              AnalyticsPoint(label: entry.key, amountKes: entry.value))
          .toList(),
      monthlySpending: monthDailyMap.entries
          .map((entry) =>
              AnalyticsPoint(label: entry.key, amountKes: entry.value))
          .toList(),
      categoryBreakdown: categoryBreakdown,
    );
  }

  DateTime _weekStart(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return dayStart.subtract(Duration(days: dayStart.weekday - 1));
  }

  List<DateTime> _weekDates(DateTime weekStart) {
    return List<DateTime>.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
  }

  String _dayShort(DateTime date) {
    return const {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    }[date.weekday]!;
  }

  double _productivityScore({
    required int completed,
    required int pending,
  }) {
    final total = completed + pending;
    if (total <= 0) {
      return 0;
    }
    return (completed / total) * 100;
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  int _asInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}
