import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';

/// Full analytics snapshot repository.
///
/// Mirrors Kotlin InsightsViewModel.loadAnalyticsTab() / loadInsightsTab():
///   • Period-scoped summary (spend, income, fees, categories, merchants)
///   • 8-week rolling sparklines per category + top merchant per category
///   • 6-month rolling history for the Insights tab trend chart
///   • Payday-pulse computation (post-income avg vs other days avg)
///   • Spend-anatomy counts (micro / medium / large)
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<AnalyticsSnapshot> watchSnapshot(AnalyticsPeriod period) async* {
    yield await _loadSnapshot(period);
    await for (final _ in _store.watchChangeStream()) {
      yield await _loadSnapshot(period);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core loader
  // ─────────────────────────────────────────────────────────────────────────

  Future<AnalyticsSnapshot> _loadSnapshot(AnalyticsPeriod period) async {
    await _store.ensureInitialized();

    final now = DateTime.now();
    final ex = _store.executor;

    // ── Period date ranges ─────────────────────────────────────────────────
    final DateTime periodStart;
    final DateTime periodEnd;
    final DateTime prevStart;
    final DateTime prevEnd;

    if (period == AnalyticsPeriod.week) {
      periodStart = _weekStart(now);
      periodEnd = periodStart.add(const Duration(days: 7));
      prevStart = periodStart.subtract(const Duration(days: 7));
      prevEnd = periodStart;
    } else {
      periodStart = DateTime(now.year, now.month, 1);
      periodEnd = _nextMonth(now.year, now.month);
      prevStart = _prevMonthStart(now.year, now.month);
      prevEnd = periodStart;
    }

    // Current ISO week (always needed for the weekly chart).
    final weekStart = _weekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));

    // 8-week lookback for sparklines & payday pulse.
    final sparkStart = DateTime.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch - const Duration(days: 56).inMilliseconds,
    );

    // 6-month lookback start for monthly history.
    final histStart = _monthsAgo(now, 5); // 5 months back = 6 months total

    // Current calendar month for events count.
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = _nextMonth(now.year, now.month);

    final pStartMs = periodStart.millisecondsSinceEpoch;
    final pEndMs = periodEnd.millisecondsSinceEpoch;
    final prevStartMs = prevStart.millisecondsSinceEpoch;
    final prevEndMs = prevEnd.millisecondsSinceEpoch;
    final wStartMs = weekStart.millisecondsSinceEpoch;
    final wEndMs = weekEnd.millisecondsSinceEpoch;
    final sparkStartMs = sparkStart.millisecondsSinceEpoch;
    final histStartMs = histStart.millisecondsSinceEpoch;
    final mStartMs = monthStart.millisecondsSinceEpoch;
    final mEndMs = monthEnd.millisecondsSinceEpoch;

    // ── Q1: Period transactions (add title for top-merchant-per-category) ──
    final txRows = await ex.runSelect(
      'SELECT amount, category, occurred_at, title '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'ORDER BY occurred_at ASC',
      [pStartMs, pEndMs],
    );

    // ── Q2: Weekly chart transactions ──────────────────────────────────────
    final weekRows = await ex.runSelect(
      'SELECT amount, occurred_at '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ?',
      [wStartMs, wEndMs],
    );

    // ── Q3: Previous period total ──────────────────────────────────────────
    final prevRows = await ex.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ?',
      [prevStartMs, prevEndMs],
    );
    final previousPeriodTotal = _asDouble(prevRows.firstOrNull?['total']);

    // ── Q4: Fees in period ─────────────────────────────────────────────────
    final feeRows = await ex.runSelect(
      'SELECT COALESCE(SUM(fee), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'AND fee IS NOT NULL AND fee > 0',
      [pStartMs, pEndMs],
    );
    final feesPaid = _asDouble(feeRows.firstOrNull?['total']);

    // ── Q4b: Top fee category ───────────────────────────────────────────────
    final topFeeRows = await ex.runSelect(
      'SELECT category, SUM(fee) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'AND fee IS NOT NULL AND fee > 0 '
      'GROUP BY category '
      'ORDER BY total DESC '
      'LIMIT 1',
      [pStartMs, pEndMs],
    );
    final topFeeCategory = topFeeRows.isNotEmpty
        ? '${topFeeRows.first['category']}'
        : null;

    // ── Q5: Tasks ──────────────────────────────────────────────────────────
    final taskRows = await ex.runSelect('SELECT status FROM tasks', const []);

    // ── Q6: Events this calendar month ────────────────────────────────────
    final eventRows = await ex.runSelect(
      'SELECT COUNT(*) AS total FROM events '
      'WHERE start_at >= ? AND start_at < ?',
      [mStartMs, mEndMs],
    );

    // ── Q7: Top merchants by spend in period ───────────────────────────────
    final merchantRows = await ex.runSelect(
      'SELECT title, SUM(amount) AS total, COUNT(*) AS c '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'GROUP BY title '
      'ORDER BY total DESC '
      'LIMIT 5',
      [pStartMs, pEndMs],
    );

    // ── Q8: Income in period ───────────────────────────────────────────────
    final incomeRows = await ex.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total, COUNT(*) AS cnt '
      'FROM incomes '
      'WHERE received_at >= ? AND received_at < ?',
      [pStartMs, pEndMs],
    );
    final totalIncome = _asDouble(incomeRows.firstOrNull?['total']);
    final incomeEventsCount = _asInt(incomeRows.firstOrNull?['cnt']);

    // ── Q9: 6-month rolling history (GROUP BY period) ──────────────────────
    final historyRows = await ex.runSelect(
      "SELECT strftime('%Y-%m', datetime(occurred_at / 1000, 'unixepoch', 'localtime')) AS pk, "
      'SUM(amount) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? '
      "GROUP BY pk "
      "ORDER BY pk ASC",
      [histStartMs],
    );

    // ── Q10: 8-week sparkline transactions (all categories) ────────────────
    final sparkRows = await ex.runSelect(
      'SELECT category, amount, occurred_at '
      'FROM transactions '
      'WHERE occurred_at >= ?',
      [sparkStartMs],
    );

    // ── Q11: Income receipt dates for payday pulse ─────────────────────────
    final incomeDateRows = await ex.runSelect(
      'SELECT received_at FROM incomes '
      'WHERE received_at >= ? '
      'ORDER BY received_at ASC',
      [sparkStartMs],
    );

    // ─────────────────────────────────────────────────────────────────────
    // Aggregate period transactions
    // ─────────────────────────────────────────────────────────────────────
    double periodTotal = 0;
    final categoryTotals = <String, double>{};
    // category → merchant → visit count (for top-merchant-per-category)
    final catMerchants = <String, Map<String, int>>{};
    int microCount = 0, mediumCount = 0, largeCount = 0;

    final daysInPeriod = periodEnd.difference(periodStart).inDays;
    final monthDailyMap = <String, double>{
      for (int i = 1; i <= daysInPeriod; i++) '$i': 0.0,
    };

    for (final row in txRows) {
      final amount = _asDouble(row['amount']);
      final category = '${row['category'] ?? 'Other'}';
      final title = '${row['title'] ?? ''}';

      periodTotal += amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;

      // Monthly daily chart — use period-relative day bucket so week mode
      // (keys "1"–"7") maps correctly instead of raw calendar day.
      final txDt = DateTime.fromMillisecondsSinceEpoch(_asInt(row['occurred_at']));
      final dayBucket = period == AnalyticsPeriod.month
          ? txDt.day
          : txDt.difference(periodStart).inDays + 1;
      monthDailyMap['$dayBucket'] = (monthDailyMap['$dayBucket'] ?? 0) + amount;

      // Merchant frequency per category
      catMerchants.putIfAbsent(category, () => {})[title] =
          (catMerchants[category]![title] ?? 0) + 1;

      // Spend anatomy
      if (amount < 500) {
        microCount++;
      } else if (amount < 2000) {
        mediumCount++;
      } else {
        largeCount++;
      }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Weekly chart map
    // ─────────────────────────────────────────────────────────────────────
    final weekDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklyMap = {for (final d in weekDayNames) d: 0.0};
    for (final row in weekRows) {
      final dt = DateTime.fromMillisecondsSinceEpoch(_asInt(row['occurred_at']));
      final key = weekDayNames[dt.weekday - 1];
      weeklyMap[key] = (weeklyMap[key] ?? 0) + _asDouble(row['amount']);
    }

    // ─────────────────────────────────────────────────────────────────────
    // 8-week sparklines per category
    // ─────────────────────────────────────────────────────────────────────
    // Index 0 = 7 weeks ago (oldest), index 7 = current week (newest).
    final catSparkline = <String, List<double>>{};
    for (final row in sparkRows) {
      final ms = _asInt(row['occurred_at']);
      final daysAgo = now.difference(DateTime.fromMillisecondsSinceEpoch(ms)).inDays;
      final weeksBucket = daysAgo ~/ 7; // 0 = current week, 7 = oldest
      final idx = 7 - weeksBucket;      // 0 = oldest, 7 = current
      if (idx < 0 || idx > 7) continue;
      final cat = '${row['category'] ?? 'Other'}';
      catSparkline.putIfAbsent(cat, () => List.filled(8, 0.0))[idx] +=
          _asDouble(row['amount']);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Category breakdown list (sorted descending by spend)
    // ─────────────────────────────────────────────────────────────────────
    final categoryBreakdown = (categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) {
          final merchants = catMerchants[e.key] ?? {};
          final topMerchant = merchants.entries.isEmpty
              ? null
              : (merchants.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .first
                  .key;
          return AnalyticsCategoryShare(
            category: e.key,
            totalKes: e.value,
            percentage:
                periodTotal > 0 ? (e.value / periodTotal) * 100 : 0,
            topMerchant: topMerchant,
            weeklySparkline: catSparkline[e.key] ?? List.filled(8, 0.0),
          );
        })
        .toList();

    // ─────────────────────────────────────────────────────────────────────
    // Top merchants
    // ─────────────────────────────────────────────────────────────────────
    final topMerchants = merchantRows
        .map((row) => AnalyticsMerchantShare(
              merchant: '${row['title'] ?? ''}',
              totalKes: _asDouble(row['total']),
              transactionCount: _asInt(row['c']),
            ))
        .toList();

    // ─────────────────────────────────────────────────────────────────────
    // 6-month history
    // ─────────────────────────────────────────────────────────────────────
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final histMap = <String, double>{
      for (final row in historyRows)
        '${row['pk']}': _asDouble(row['total']),
    };

    final monthlyHistory = <MonthlyTotalPoint>[];
    for (int offset = 5; offset >= 0; offset--) {
      int y = now.year;
      int m = now.month - offset;
      while (m <= 0) {
        m += 12;
        y--;
      }
      final key = '$y-${m.toString().padLeft(2, '0')}';
      monthlyHistory.add(MonthlyTotalPoint(
        periodKey: key,
        monthLabel: monthNames[m - 1],
        totalKes: histMap[key] ?? 0,
        year: y,
        month: m,
      ));
    }

    // ─────────────────────────────────────────────────────────────────────
    // Payday pulse
    // ─────────────────────────────────────────────────────────────────────
    double? postIncomeAvg;
    double? otherDaysAvg;

    if (incomeDateRows.isNotEmpty) {
      // Identify post-income windows (7 days after each income receipt).
      final postIncomeDays = <DateTime>{};
      for (final row in incomeDateRows) {
        final incomeDay = _dayOf(DateTime.fromMillisecondsSinceEpoch(
          _asInt(row['received_at']),
        ));
        for (int i = 1; i <= 7; i++) {
          postIncomeDays.add(incomeDay.add(Duration(days: i)));
        }
      }

      // Aggregate daily spend from the sparkline transactions.
      final dailySpend = <DateTime, double>{};
      for (final row in sparkRows) {
        final day = _dayOf(
          DateTime.fromMillisecondsSinceEpoch(_asInt(row['occurred_at'])),
        );
        dailySpend[day] = (dailySpend[day] ?? 0) + _asDouble(row['amount']);
      }

      if (dailySpend.isNotEmpty) {
        final postEntries =
            dailySpend.entries.where((e) => postIncomeDays.contains(e.key)).toList();
        final otherEntries =
            dailySpend.entries.where((e) => !postIncomeDays.contains(e.key)).toList();

        if (postEntries.isNotEmpty) {
          postIncomeAvg = postEntries.map((e) => e.value).reduce((a, b) => a + b) /
              postEntries.length;
        }
        if (otherEntries.isNotEmpty) {
          otherDaysAvg = otherEntries.map((e) => e.value).reduce((a, b) => a + b) /
              otherEntries.length;
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Tasks & events
    // ─────────────────────────────────────────────────────────────────────
    final completed = taskRows.where((r) => '${r['status']}' == 'completed').length;
    final pending = taskRows.length - completed;
    final total = completed + pending;
    final productivity = total > 0 ? (completed / total) * 100 : 0.0;
    final eventsCount = _asInt(eventRows.firstOrNull?['total']);

    // ─────────────────────────────────────────────────────────────────────
    // Average daily spending
    // ─────────────────────────────────────────────────────────────────────
    final elapsed = now.isBefore(periodEnd)
        ? now.difference(periodStart).inDays + 1
        : periodEnd.difference(periodStart).inDays;
    final avgDaily = periodTotal / (elapsed <= 0 ? 1 : elapsed);

    // ─────────────────────────────────────────────────────────────────────
    // Build snapshot
    // ─────────────────────────────────────────────────────────────────────
    return AnalyticsSnapshot(
      totalSpentThisPeriodKes: periodTotal,
      totalIncomeThisPeriodKes: totalIncome,
      previousPeriodTotalKes: previousPeriodTotal,
      averageDailySpendingKes: avgDaily,
      feesPaidKes: feesPaid,
      totalTxCount: txRows.length,
      microTxCount: microCount,
      mediumTxCount: mediumCount,
      largeTxCount: largeCount,
      totalTasksCompleted: completed,
      totalTasksPending: pending,
      totalEventsThisMonth: eventsCount,
      productivityScore: productivity,
      weeklySpending: weekDayNames
          .map((d) => AnalyticsPoint(label: d, amountKes: weeklyMap[d]!))
          .toList(),
      monthlySpending: List.generate(
        daysInPeriod,
        (i) => AnalyticsPoint(
          label: '${i + 1}',
          amountKes: monthDailyMap['${i + 1}'] ?? 0,
        ),
      ),
      categoryBreakdown: categoryBreakdown,
      topMerchants: topMerchants,
      monthlyHistory: monthlyHistory,
      postIncomeAvgDailySpendKes: postIncomeAvg,
      otherDaysAvgDailySpendKes: otherDaysAvg,
      topFeeCategory: topFeeCategory,
      incomeEventsCount: incomeEventsCount,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phase-4 additional queries
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<double> getMonthTotalSpend(int year, int month) async {
    await _store.ensureInitialized();
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = _nextMonth(year, month).millisecondsSinceEpoch;
    final rows = await _store.executor.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ?',
      [start, end],
    );
    return _asDouble(rows.firstOrNull?['total']);
  }

  @override
  Future<String?> getTopCategoryAllTime() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT category, SUM(amount) AS total '
      'FROM transactions '
      'GROUP BY category '
      'ORDER BY total DESC '
      'LIMIT 1',
      const [],
    );
    if (rows.isEmpty) return null;
    return '${rows.first['category']}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime _nextMonth(int year, int month) =>
      month < 12 ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);

  DateTime _prevMonthStart(int year, int month) =>
      month > 1 ? DateTime(year, month - 1, 1) : DateTime(year - 1, 12, 1);

  DateTime _monthsAgo(DateTime now, int months) {
    int y = now.year;
    int m = now.month - months;
    while (m <= 0) {
      m += 12;
      y--;
    }
    return DateTime(y, m, 1);
  }

  DateTime _dayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  double _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  int _asInt(Object? v) {
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
