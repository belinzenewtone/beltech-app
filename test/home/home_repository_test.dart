import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/home/data/repositories/home_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late HomeRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = HomeRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('watchOverview reflects newly added same-day transaction', () async {
    final initial = await repository.watchOverview().first;
    final nextOverview = repository.watchOverview().skip(1).first;

    await store.addTransaction(
      title: 'Home Sync Check',
      category: 'Other',
      amountKes: 500,
      occurredAt: DateTime.now(),
    );

    final updated = await nextOverview.timeout(const Duration(seconds: 2));
    expect(updated.todayKes, greaterThanOrEqualTo(initial.todayKes));
    expect(
      updated.recentTransactions.any((tx) => tx.title == 'Home Sync Check'),
      isTrue,
    );
  });
}
