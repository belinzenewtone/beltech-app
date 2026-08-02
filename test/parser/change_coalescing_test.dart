// Phase P4 — the change stream coalesces bursts.
//
// A single mutation must publish immediately (snappy UI); a burst of mutations
// must collapse into far fewer publishes than mutations (no rebuild storm).

import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  setUp(() => store = AppDriftStore());
  tearDown(() => store.dispose());

  Future<void> addOne(int i) => store.addTransaction(
    title: 'txn $i',
    category: 'Food',
    amountKes: 1,
    occurredAt: DateTime(2026, 3, 15),
  );

  test('an isolated change publishes immediately (leading edge)', () async {
    final ticks = <int>[];
    final sub = store.watchChangeStream().listen(ticks.add);
    await store.ensureInitialized();

    await addOne(0);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(ticks, isNotEmpty, reason: 'first change should fire without waiting');

    await sub.cancel();
  });

  test('a burst of 50 mutations collapses into far fewer publishes', () async {
    final ticks = <int>[];
    final sub = store.watchChangeStream().listen(ticks.add);
    await store.ensureInitialized();

    // Fire 50 mutations back-to-back within one coalescing window.
    for (var i = 0; i < 50; i++) {
      await addOne(i);
    }
    // Let the trailing edge flush.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(ticks.length, lessThan(50),
        reason: '50 mutations must not become 50 publishes');
    expect(ticks.length, greaterThanOrEqualTo(1));

    await sub.cancel();
  });

  test('watchers still observe the latest state after a burst', () async {
    for (var i = 0; i < 20; i++) {
      await addOne(i);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // A fresh watch reads current state on subscribe, regardless of coalescing.
    final snapshot = await store.watchExpensesSnapshot().first;
    expect(snapshot.categories.first.category, 'Food');
    expect(snapshot.categories.first.totalKes, 20.0);
  });
}
