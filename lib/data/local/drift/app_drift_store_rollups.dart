part of 'app_drift_store.dart';

/// Phase P3 — incremental rollup maintenance.
///
/// These functions keep `rollup_daily` and `rollup_category` in exact parity
/// with the `transactions` table, so the dashboard aggregates read tiny rollup
/// rows instead of scanning the ledger. Every transaction insert/delete applies
/// a signed delta; [_rebuildRollupsImpl] is the authoritative recompute used at
/// startup and as a self-heal.

/// Local-midnight epoch (ms) for a transaction timestamp — the daily bucket key.
/// Matches the day-aligned range bounds the loaders use (todayStart, weekStart,
/// monthStart are all local midnights).
int _dayKeyFor(int occurredAtMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(occurredAtMs);
  return DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
}

/// Apply a single transaction to the rollups. [sign] is +1 on insert, -1 on
/// delete. Uses UPSERT so a new bucket/category row is created on first touch.
Future<void> _applyRollupDeltaImpl(
  AppDriftStore store, {
  required String category,
  required double amount,
  required int occurredAtMs,
  required int sign,
}) async {
  final delta = amount * sign;
  final dayKey = _dayKeyFor(occurredAtMs);
  await store._db.runCustom(
    'INSERT INTO rollup_daily(day_start_ms, total_amount, txn_count) '
    'VALUES (?, ?, ?) '
    'ON CONFLICT(day_start_ms) DO UPDATE SET '
    'total_amount = total_amount + excluded.total_amount, '
    'txn_count = txn_count + excluded.txn_count',
    [dayKey, delta, sign],
  );
  await store._db.runCustom(
    'INSERT INTO rollup_category(category, total_amount, txn_count) '
    'VALUES (?, ?, ?) '
    'ON CONFLICT(category) DO UPDATE SET '
    'total_amount = total_amount + excluded.total_amount, '
    'txn_count = txn_count + excluded.txn_count',
    [category, delta, sign],
  );
}

/// Apply many transactions in one pass (bulk import wave). Deltas are summed in
/// memory first so each affected bucket/category is written once, not per row.
Future<void> _applyRollupDeltasBulkImpl(
  AppDriftStore store,
  List<({String category, double amount, int occurredAtMs})> txns, {
  required int sign,
}) async {
  if (txns.isEmpty) return;
  final dayAgg = <int, ({double amount, int count})>{};
  final catAgg = <String, ({double amount, int count})>{};
  for (final t in txns) {
    final dayKey = _dayKeyFor(t.occurredAtMs);
    final d = dayAgg[dayKey];
    dayAgg[dayKey] =
        (amount: (d?.amount ?? 0) + t.amount, count: (d?.count ?? 0) + 1);
    final c = catAgg[t.category];
    catAgg[t.category] =
        (amount: (c?.amount ?? 0) + t.amount, count: (c?.count ?? 0) + 1);
  }
  for (final e in dayAgg.entries) {
    await store._db.runCustom(
      'INSERT INTO rollup_daily(day_start_ms, total_amount, txn_count) '
      'VALUES (?, ?, ?) ON CONFLICT(day_start_ms) DO UPDATE SET '
      'total_amount = total_amount + excluded.total_amount, '
      'txn_count = txn_count + excluded.txn_count',
      [e.key, e.value.amount * sign, e.value.count * sign],
    );
  }
  for (final e in catAgg.entries) {
    await store._db.runCustom(
      'INSERT INTO rollup_category(category, total_amount, txn_count) '
      'VALUES (?, ?, ?) ON CONFLICT(category) DO UPDATE SET '
      'total_amount = total_amount + excluded.total_amount, '
      'txn_count = txn_count + excluded.txn_count',
      [e.key, e.value.amount * sign, e.value.count * sign],
    );
  }
}

/// Authoritative recompute from `transactions`. O(n) — run at startup and as a
/// self-heal, never per-write.
Future<void> _rebuildRollupsImpl(AppDriftStore store) async {
  await store._db.runCustom('DELETE FROM rollup_daily');
  await store._db.runCustom('DELETE FROM rollup_category');

  final rows = await store._db.runSelect(
    'SELECT category, amount, occurred_at FROM transactions',
    const [],
  );
  if (rows.isEmpty) return;

  final txns = rows
      .map(
        (r) => (
          category: (r['category'] ?? 'Other') as String,
          amount: store._asDouble(r['amount']),
          occurredAtMs: store._asInt(r['occurred_at']),
        ),
      )
      .toList(growable: false);
  await _applyRollupDeltasBulkImpl(store, txns, sign: 1);
}

/// Sum of transaction amounts in a day-aligned range, read from `rollup_daily`.
/// Equivalent to `SUM(amount) WHERE occurred_at >= start AND < end` for
/// day-aligned bounds — but reads ≤31 rows for a month instead of scanning.
Future<double> _sumDailyBetweenImpl(
  AppDriftStore store,
  DateTime start,
  DateTime end,
) async {
  final rows = await store._db.runSelect(
    'SELECT COALESCE(SUM(total_amount), 0) AS total FROM rollup_daily '
    'WHERE day_start_ms >= ? AND day_start_ms < ?',
    [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
  );
  return store._asDouble(rows.first['total']);
}

/// All-time per-category totals from `rollup_category`, highest first.
Future<List<CategoryTotalRecord>> _loadCategoryRollupsImpl(
  AppDriftStore store,
) async {
  final rows = await store._db.runSelect(
    // txn_count > 0 so a category whose transactions were all deleted or
    // recategorised drops out entirely — matching the old GROUP BY, which
    // returned no row for an empty category (no spurious "KES 0" entries).
    'SELECT category, total_amount FROM rollup_category '
    'WHERE txn_count > 0 '
    'ORDER BY total_amount DESC',
    const [],
  );
  return rows
      .map(
        (r) => CategoryTotalRecord(
          category: (r['category'] ?? 'Other') as String,
          totalKes: store._asDouble(r['total_amount']),
        ),
      )
      .toList(growable: false);
}
