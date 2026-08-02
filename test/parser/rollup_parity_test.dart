// Phase P3 — rollup parity: the materialized aggregates must exactly equal the
// ledger, both after an authoritative rebuild and after incremental deltas.
// Ground truth is computed independently from the seed list (not from a second
// DB query), so this proves the rollups are correct in absolute terms.

import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/app_drift_store_mutations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;

  setUp(() => store = AppDriftStore());
  tearDown(() => store.dispose());

  final base = DateTime(2026, 3, 15, 9);
  final seed = <({String category, double amount, DateTime at})>[
    (category: 'Food', amount: 250.0, at: base),
    (category: 'Food', amount: 120.5, at: base.add(const Duration(hours: 6))),
    (category: 'Transport', amount: 80.0, at: base),
    (category: 'Transport', amount: 80.0, at: base.subtract(const Duration(days: 1))),
    (category: 'Utilities', amount: 1450.0, at: base.subtract(const Duration(days: 3))),
    (category: 'Food', amount: 60.0, at: base.subtract(const Duration(days: 10))),
    (category: 'Shopping', amount: 999.99, at: base.subtract(const Duration(days: 40))),
    (category: 'Transport', amount: 45.0, at: base.add(const Duration(days: 2))),
  ];

  Future<void> insertSeed() async {
    for (final s in seed) {
      await store.addTransaction(
        title: '${s.category} txn',
        category: s.category,
        amountKes: s.amount,
        occurredAt: s.at,
      );
    }
  }

  Map<String, double> truthCategories() {
    final t = <String, double>{};
    for (final s in seed) {
      t[s.category] = (t[s.category] ?? 0) + s.amount;
    }
    return t;
  }

  // Mirrors the loader's `occurred_at >= start AND < end` semantics.
  double truthRange(DateTime start, DateTime end) {
    var sum = 0.0;
    for (final s in seed) {
      if (!s.at.isBefore(start) && s.at.isBefore(end)) sum += s.amount;
    }
    return sum;
  }

  Future<Map<String, double>> rollupCategories() async => {
    for (final c in await store.loadCategoryRollups()) c.category: c.totalKes,
  };

  test('rebuild produces category totals identical to the ledger', () async {
    await insertSeed();
    await store.rebuildRollups();

    final rollup = await rollupCategories();
    final truth = truthCategories();
    expect(rollup.length, truth.length);
    for (final e in truth.entries) {
      expect(rollup[e.key], closeTo(e.value, 1e-9), reason: 'category ${e.key}');
    }
  });

  test('daily rollup range sums equal the ledger (today/week/month/year)', () async {
    await insertSeed();
    await store.rebuildRollups();

    final ranges = <(DateTime, DateTime)>[
      (DateTime(2026, 3, 15), DateTime(2026, 3, 16)),
      (DateTime(2026, 3, 9), DateTime(2026, 3, 16)),
      (DateTime(2026, 3, 1), DateTime(2026, 4, 1)),
      (DateTime(2026, 1, 1), DateTime(2027, 1, 1)),
    ];
    for (final (start, end) in ranges) {
      expect(
        await store.sumDailyBetween(start, end),
        closeTo(truthRange(start, end), 1e-9),
        reason: 'range $start..$end',
      );
    }
  });

    test('addTransaction maintains rollups in parity with a full rebuild', () async {
    // addTransaction maintains the rollups itself — no manual delta here.
    await insertSeed();
    final incremental = await rollupCategories();

    await store.rebuildRollups();
    final rebuilt = await rollupCategories();

    expect(incremental.keys.toSet(), rebuilt.keys.toSet());
    for (final k in rebuilt.keys) {
      expect(incremental[k], closeTo(rebuilt[k]!, 1e-9), reason: k);
    }
  });

  test('a -1 delta exactly reverses a +1 (arithmetic primitive)', () async {
    await insertSeed();
    await store.rebuildRollups();
    final rebuilt = await rollupCategories();

    final removed = seed.first;
    await store.applyRollupDelta(
      category: removed.category,
      amount: removed.amount,
      occurredAtMs: removed.at.millisecondsSinceEpoch,
      sign: -1,
    );
    final after = await rollupCategories();
    expect(after[removed.category],
        closeTo(rebuilt[removed.category]! - removed.amount, 1e-9));
  });

  test('empty ledger yields empty rollups', () async {
    await store.rebuildRollups();
    expect(await store.loadCategoryRollups(), isEmpty);
    expect(await store.sumDailyBetween(DateTime(2020), DateTime(2030)), 0);
  });

  // Audit regression: a category whose only transaction is deleted must drop
  // out of the rollups (no "Zombie — KES 0" row like a naive UPSERT leaves).
  test('deleting a category\'s last txn removes it from rollups', () async {
    await store.addTransaction(
      title: 'x',
      category: 'Zombie',
      amountKes: 42,
      occurredAt: base,
    );
    expect((await store.loadCategoryRollups()).map((c) => c.category),
        contains('Zombie'));

    final rows = await store.executor.runSelect(
      "SELECT id FROM transactions WHERE category = 'Zombie'",
      const [],
    );
    await store.deleteTransaction((rows.first['id'] as num).toInt());

    expect((await store.loadCategoryRollups()).map((c) => c.category),
        isNot(contains('Zombie')));
  });
}
