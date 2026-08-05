import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/review/domain/entities/monthly_wrapped_data.dart';

/// Loads all data for the Monthly Wrapped screen.
/// Mirrors Kotlin MonthlyWrappedViewModel data loading logic.
class MonthlyWrappedRepositoryImpl {
  MonthlyWrappedRepositoryImpl(this._store);

  final AppDriftStore _store;

  Future<MonthlyWrappedData> loadWrapped({
    required int year,
    required int month,
  }) async {
    await _store.ensureInitialized();

    final monthStart = DateTime(year, month, 1).millisecondsSinceEpoch;
    final monthEndDt = month < 12
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    final monthEndMs = monthEndDt.millisecondsSinceEpoch;

    final prevStartDt = month > 1
        ? DateTime(year, month - 1, 1)
        : DateTime(year - 1, 12, 1);
    final prevStartMs = prevStartDt.millisecondsSinceEpoch;

    final ex = _store.executor;

    // ── Total spend + tx count ─────────────────────────────────────────────
    final totalRows = await ex.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total, COUNT(*) AS cnt '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ?',
      [monthStart, monthEndMs],
    );
    final totalSpent = _asDouble(totalRows.firstOrNull?['total']);
    final txCount = _asInt(totalRows.firstOrNull?['cnt']);

    // ── Previous month total ───────────────────────────────────────────────
    final prevRows = await ex.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ?',
      [prevStartMs, monthStart],
    );
    final prevTotal = _asDouble(prevRows.firstOrNull?['total']);

    // ── Top 5 categories ──────────────────────────────────────────────────
    final catRows = await ex.runSelect(
      'SELECT category, SUM(amount) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'GROUP BY category '
      'ORDER BY total DESC '
      'LIMIT 5',
      [monthStart, monthEndMs],
    );
    final topCategories = catRows.asMap().entries.map((e) {
      final catTotal = _asDouble(e.value['total']);
      return WrappedCategoryRow(
        category: '${e.value['category'] ?? 'Other'}',
        totalKes: catTotal,
        percentage: totalSpent > 0 ? (catTotal / totalSpent) * 100 : 0,
        rank: e.key + 1,
      );
    }).toList();

    // ── Biggest single transaction ────────────────────────────────────────
    final biggestRows = await ex.runSelect(
      'SELECT title, amount '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'ORDER BY amount DESC '
      'LIMIT 1',
      [monthStart, monthEndMs],
    );
    final biggestTxMerchant = biggestRows.isNotEmpty
        ? '${biggestRows.first['title'] ?? ''}'
        : null;
    final biggestTxAmount = biggestRows.isNotEmpty
        ? _asDouble(biggestRows.first['amount'])
        : 0.0;

    // ── Most visited merchant (by tx count) ───────────────────────────────
    final topMerchantRows = await ex.runSelect(
      'SELECT title, COUNT(*) AS cnt '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'GROUP BY title '
      'ORDER BY cnt DESC '
      'LIMIT 1',
      [monthStart, monthEndMs],
    );
    final topMerchant = topMerchantRows.isNotEmpty
        ? '${topMerchantRows.first['title'] ?? ''}'
        : null;
    final topMerchantCount = topMerchantRows.isNotEmpty
        ? _asInt(topMerchantRows.first['cnt'])
        : 0;

    // ── Fees ──────────────────────────────────────────────────────────────
    final feeRows = await ex.runSelect(
      'SELECT COALESCE(SUM(fee), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'AND fee IS NOT NULL AND fee > 0',
      [monthStart, monthEndMs],
    );
    final feesPaid = _asDouble(feeRows.firstOrNull?['total']);

    // ── Active days ───────────────────────────────────────────────────────
    final activeDaysRows = await ex.runSelect(
      "SELECT COUNT(DISTINCT strftime('%Y-%m-%d', "
      "datetime(occurred_at / 1000, 'unixepoch', 'localtime'))) AS days "
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ?',
      [monthStart, monthEndMs],
    );
    final activeDays = _asInt(activeDaysRows.firstOrNull?['days']);

    // ── Income for the month ──────────────────────────────────────────────
    final incomeRows = await ex.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM incomes '
      'WHERE received_at >= ? AND received_at < ?',
      [monthStart, monthEndMs],
    );
    final incomeTotal = _asDouble(incomeRows.firstOrNull?['total']);

    // ── Fuliza usage ──────────────────────────────────────────────────────
    final fulizaRows = await ex.runSelect(
      'SELECT COUNT(*) AS cnt, COALESCE(SUM(amount), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      "AND (UPPER(transaction_type) = 'FULIZA' OR LOWER(category) = 'fuliza')",
      [monthStart, monthEndMs],
    );
    final fulizaCount = _asInt(fulizaRows.firstOrNull?['cnt']);
    final fulizaTotal = _asDouble(fulizaRows.firstOrNull?['total']);

    // ── Days in month ─────────────────────────────────────────────────────
    final daysInMonth = monthEndDt.difference(DateTime(year, month, 1)).inDays;

    return MonthlyWrappedData(
      year: year,
      month: month,
      totalSpentKes: totalSpent,
      prevMonthTotalKes: prevTotal,
      txCount: txCount,
      topCategories: topCategories,
      biggestTxMerchant: biggestTxMerchant,
      biggestTxAmount: biggestTxAmount,
      topMerchant: topMerchant,
      topMerchantCount: topMerchantCount,
      feesPaidKes: feesPaid,
      activeDays: activeDays,
      daysInMonth: daysInMonth,
      incomeTotalKes: incomeTotal,
      fulizaUsedCount: fulizaCount,
      fulizaTotal: fulizaTotal,
    );
  }

  double _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  int _asInt(Object? v) {
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
