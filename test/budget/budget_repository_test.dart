import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late BudgetRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = BudgetRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('upsertTarget and snapshot include category spending', () async {
    await repository.upsertTarget(category: 'Food', monthlyLimitKes: 10000);
    final month = DateTime.now();
    final snapshot = await repository.watchMonthlySnapshot(month).first;
    final food = snapshot.items.firstWhere((item) => item.category == 'Food');
    expect(food.monthlyLimitKes, 10000);
    expect(food.spentKes, greaterThanOrEqualTo(0));
  });
}
