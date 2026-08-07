import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/domain/entities/monthly_breakdown_data.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';

/// Full analytics snapshot repository.
///
/// Mirrors Kotlin InsightsViewModel.loadAnalyticsTab() / loadInsightsTab():
///   • Period-scoped summary (spend, income, fees, categories, merchants)
///   • 8-week rolling sparklines per category + top merchant per category
///   • 6-month rolling history + per-month breakdown for the Insights tab
///   • Payday-pulse computation (post-income avg vs other days avg)
///   • Spend-anatomy counts (micro / medium / large)
///
/// Expenses are rows whose `transaction_type` is 'expense' (the default);
/// income-type rows live in the separate `incomes` table.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._store);

  final AppDriftStore _store;

  /// Rows with this transaction_type (or NULL, the legacy default) are
  /// treated as expenses — matching the finance records the app writes.
  static const _expenseTypeFilter =
      "AND COALESCE(transaction_type, 'expense') = 'expense'";

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
      // Kotlin "vs Last Month" — compare against the previous calendar month.
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
      '$_expenseTypeFilter '
      'ORDER BY occurred_at ASC',
      [pStartMs, pEndMs],
    );

    // ── Q2: Weekly chart transactions (expenses only) ──────────────────────
    final weekRows = await ex.runSelect(
      'SELECT amount, occurred_at '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      '$_expenseTypeFilter',
      [wStartMs, wEndMs],
    );

    // ── Q3: Previous period total (expenses only) ──────────────────────────
    final prevRows = await ex.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      '$_expenseTypeFilter',
      [prevStartMs, prevEndMs],
    );
    final previousPeriodTotal = _asDouble(prevRows.firstOrNull?['total']);

    // ── Q4: Fees in period (expenses only) ─────────────────────────────────
    final feeRows = await ex.runSelect(
      'SELECT COALESCE(SUM(fee), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      '$_expenseTypeFilter '
      'AND fee IS NOT NULL AND fee > 0',
      [pStartMs, pEndMs],
    );
    final feesPaid = _asDouble(feeRows.firstOrNull?['total']);

    // ── Q4b: Top fee category (expenses only) ───────────────────────────────
    final topFeeRows = await ex.runSelect(
      'SELECT category, SUM(fee) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      '$_expenseTypeFilter '
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

    // ── Q7: Top merchants by spend in period (expenses only) ───────────────
    final merchantRows = await ex.runSelect(
      'SELECT title, SUM(amount) AS total, COUNT(*) AS c '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      '$_expenseTypeFilter '
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

    // ── Q9: 6-month rolling history (GROUP BY period, expenses only) ────────
    final historyRows = await ex.runSelect(
      "SELECT strftime('%Y-%m', datetime(occurred_at / 1000, 'unixepoch', 'localtime')) AS pk, "
      'SUM(amount) AS total, COUNT(*) AS c '
      'FROM transactions '
      'WHERE occurred_at >= ? '
      '$_expenseTypeFilter '
      "GROUP BY pk "
      "ORDER BY pk ASC",
      [histStartMs],
    );

    // ── Q10: 8-week sparkline transactions (all categories, expenses only) ─
    final sparkRows = await ex.runSelect(
      'SELECT category, amount, occurred_at '
      'FROM transactions '
      'WHERE occurred_at >= ? '
      '$_expenseTypeFilter',
      [sparkStartMs],
    );

    // ── Q11: Income receipt dates for payday pulse (6-month window) ────────
    final incomeDateRows = await ex.runSelect(
      'SELECT received_at FROM incomes '
      'WHERE received_at >= ? '
      'ORDER BY received_at ASC',
      [histStartMs],
    );

    // ── Q12: 6-month window expenses for the Insights tab ──────────────────
    final windowRows = await ex.runSelect(
      'SELECT category, amount, occurred_at '
      'FROM transactions '
      'WHERE occurred_at >= ? '
      '$_expenseTypeFilter',
      [histStartMs],
    );

    // ── Q13: 6-month window income totals per month (Insights tab) ─────────
    final windowIncomeRows = await ex.runSelect(
      "SELECT strftime('%Y-%m', datetime(received_at / 1000, 'unixepoch', 'localtime')) AS pk, "
      'SUM(amount) AS total '
      'FROM incomes '
      'WHERE received_at >= ? '
      "GROUP BY pk",
      [histStartMs],
    );

    // ─────────────────────────────────────────────────────────────────────
    // Aggregate period transactions
    // ─────────────────────────────────────────────────────────────────────
    double periodTotal = 0;
    final categoryTotals = <String, double>{};
    final categoryTxCounts = <String, int>{};
    // category → merchant → visit count (for top-merchant-per-category)
    final catMerchants = <String, Map<String, int>>{};

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
      categoryTxCounts[category] = (categoryTxCounts[category] ?? 0) + 1;

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
            txCount: categoryTxCounts[e.key] ?? 0,
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
    // 6-month history + Insights-tab payload
    // ─────────────────────────────────────────────────────────────────────
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final histMap = <String, double>{
      for (final row in historyRows)
        '${row['pk']}': _asDouble(row['total']),
    };
    final histTxCount = <String, int>{
      for (final row in historyRows) '${row['pk']}': _asInt(row['c']),
    };
    final incomeByMonth = <String, double>{
      for (final row in windowIncomeRows)
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
        totalIncomeKes: incomeByMonth[key] ?? 0,
        txCount: histTxCount[key] ?? 0,
        monthOffset: -offset,
      ));
    }

    // Insights-tab aggregates (Kotlin loadInsightsTab).
    final expenseMonths = monthlyHistory.where((p) => p.totalKes > 0).toList();
    final totalTracked =
        expenseMonths.fold<double>(0, (sum, p) => sum + p.totalKes);
    final avgExpense =
        expenseMonths.isEmpty ? 0.0 : totalTracked / expenseMonths.length;

    // Top category all-time over the window.
    final catTotalsWindow = <String, double>{};
    for (final row in windowRows) {
      final cat = '${row['category'] ?? 'Other'}';
      catTotalsWindow[cat] = (catTotalsWindow[cat] ?? 0) + _asDouble(row['amount']);
    }
    final catTotalsSorted = catTotalsWindow.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = catTotalsSorted.fold<double>(0, (s, e) => s + e.value);
    final topCategoryAllTime = catTotalsSorted.isEmpty ? null : catTotalsSorted.first.key;
    final topCategoryAllTimePct = (topCategoryAllTime != null && grandTotal > 0)
        ? (catTotalsSorted.first.value / grandTotal) * 100
        : null;

    // Trend: last-3 vs previous-3 month average, ±5% band.
    final last3 = monthlyHistory.length >= 3
        ? monthlyHistory.sublist(monthlyHistory.length - 3)
        : monthlyHistory;
    final prev3 = monthlyHistory.length >= 3
        ? monthlyHistory.sublist(0, 3)
        : monthlyHistory;
    final last3Avg =
        last3.fold<double>(0, (s, p) => s + p.totalKes) /
            (last3.isEmpty ? 1 : last3.length);
    final prev3Avg =
        prev3.fold<double>(0, (s, p) => s + p.totalKes) /
            (prev3.isEmpty ? 1 : prev3.length);
    final trendDiff = (last3Avg - prev3Avg) / (prev3Avg > 0 ? prev3Avg : 1.0);
    final trend = trendDiff > 0.05
        ? 'increasing'
        : trendDiff < -0.05
            ? 'decreasing'
            : 'stable';

    // Per-month breakdown (Kotlin: reversed, delta vs previous month).
    final monthBreakdown = <MonthlyBreakdownData>[];
    for (int i = 0; i < monthlyHistory.length; i++) {
      final bar = monthlyHistory[i];
      final prevExpense =
          i > 0 ? monthlyHistory[i - 1].totalKes : 0.0;
      final monthTxns = <String, double>{};
      for (final row in windowRows) {
        final dt = DateTime.fromMillisecondsSinceEpoch(_asInt(row['occurred_at']));
        if (dt.year == bar.year && dt.month == bar.month) {
          final cat = '${row['category'] ?? 'Other'}';
          monthTxns[cat] = (monthTxns[cat] ?? 0) + _asDouble(row['amount']);
        }
      }
      final monthTotal = monthTxns.values.fold<double>(0, (s, v) => s + v);
      final topCats = (monthTxns.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .map((e) => MonthlyBreakdownCategory(
                category: e.key,
                totalKes: e.value,
                pct: monthTotal > 0 ? (e.value / monthTotal) * 100 : 0,
              ))
          .toList();
      monthBreakdown.add(MonthlyBreakdownData(
        periodKey: bar.periodKey,
        monthLabel: bar.monthLabel,
        year: bar.year,
        month: bar.month,
        totalKes: bar.totalKes,
        previousMonthTotalKes: prevExpense,
        txCount: bar.txCount,
        topCategories: topCats,
      ));
    }
    monthBreakdown.sort((a, b) {
      final byYear = b.year.compareTo(a.year);
      return byYear != 0 ? byYear : b.month.compareTo(a.month);
    });

    // Spend anatomy over the 6-month window (Kotlin micro/medium/large).
    int microCount6 = 0, mediumCount6 = 0, largeCount6 = 0;
    for (final row in windowRows) {
      final amount = _asDouble(row['amount']);
      if (amount < 500) {
        microCount6++;
      } else if (amount < 2000) {
        mediumCount6++;
      } else {
        largeCount6++;
      }
    }

    // Payday pulse (Kotlin: RECEIVED rows, window start→now, take 12, ≥2).
    double? postIncomeAvg;
    double? otherDaysAvg;
    if (incomeDateRows.length >= 2) {
      final incomeDates = incomeDateRows.take(12).map((row) => _dayOf(
            DateTime.fromMillisecondsSinceEpoch(_asInt(row['received_at'])),
          ));
      final postIncomeDays = <DateTime>{};
      for (final incomeDay in incomeDates) {
        for (int i = 0; i <= 6; i++) {
          postIncomeDays.add(incomeDay.add(Duration(days: i)));
        }
      }
      final dailySpend = <DateTime, double>{};
      for (final row in windowRows) {
        final day = _dayOf(
          DateTime.fromMillisecondsSinceEpoch(_asInt(row['occurred_at'])),
        );
        dailySpend[day] = (dailySpend[day] ?? 0) + _asDouble(row['amount']);
      }
      var postTotal = 0.0, postDays = 0;
      var otherTotal = 0.0, otherDays = 0;
      dailySpend.forEach((day, total) {
        if (postIncomeDays.contains(day)) {
          postTotal += total;
          postDays++;
        } else {
          otherTotal += total;
          otherDays++;
        }
      });
      if (postDays > 0 && otherDays > 0) {
        postIncomeAvg = postTotal / postDays;
        otherDaysAvg = otherTotal / otherDays;
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
      // Spend anatomy is reported over the 6-month Insights window (Kotlin
      // InsightsSizeBreakdown) — the Insights-tab Spend Anatomy card uses it.
      microTxCount: microCount6,
      mediumTxCount: mediumCount6,
      largeTxCount: largeCount6,
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
      monthBreakdown: monthBreakdown,
      postIncomeAvgDailySpendKes: postIncomeAvg,
      otherDaysAvgDailySpendKes: otherDaysAvg,
      topFeeCategory: topFeeCategory,
      // Income-event count from the 6-month window (Kotlin Payday Pulse uses
      // the window's RECEIVED rows, capped at 12).
      incomeEventsCount: incomeDateRows.length,
      avgMonthlyExpenseKes: avgExpense,
      totalTrackedKes: totalTracked,
      topCategoryAllTime: topCategoryAllTime,
      topCategoryAllTimePct: topCategoryAllTimePct,
      trend: trend,
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
      'WHERE occurred_at >= ? AND occurred_at < ? '
      '$_expenseTypeFilter',
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
      'WHERE $_expenseTypeFilter '
      'GROUP BY category '
      'ORDER BY total DESC '
      'LIMIT 1',
      const [],
    );
    if (rows.isEmpty) return null;
    return '${rows.first['category']}';
  }

  @override
  Future<List<CategoryTransaction>> getCategoryTransactions(
    String category, {
    DateTime? start,
    DateTime? end,
  }) async {
    await _store.ensureInitialized();
    final startMs = start?.millisecondsSinceEpoch;
    final endMs = end?.millisecondsSinceEpoch;
    final rows = await _store.executor.runSelect(
      'SELECT id, title, amount, occurred_at, fee '
      'FROM transactions '
      'WHERE category = ? '
      '$_expenseTypeFilter '
      '${startMs != null ? 'AND occurred_at >= ? ' : ''}'
      '${endMs != null ? 'AND occurred_at < ? ' : ''}'
      'ORDER BY occurred_at DESC',
      [
        category,
        ?startMs,
        ?endMs,
      ],
    );
    return rows
        .map((row) => CategoryTransaction(
              id: _asInt(row['id']),
              title: '${row['title'] ?? ''}',
              amountKes: _asDouble(row['amount']),
              occurredAt: DateTime.fromMillisecondsSinceEpoch(
                _asInt(row['occurred_at']),
              ),
              feeKes: row['fee'] == null ? null : _asDouble(row['fee']),
            ))
        .toList();
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
