import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/income/data/repositories/income_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late IncomeRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = IncomeRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('add/update/delete income works', () async {
    await repository.addIncome(title: 'Consulting', amountKes: 1500);
    var items = await repository.watchIncomes().first;
    final created = items.firstWhere((item) => item.title == 'Consulting');
    expect(created.amountKes, 1500);

    await repository.updateIncome(
      incomeId: created.id,
      title: 'Consulting Updated',
      amountKes: 2200,
      receivedAt: created.receivedAt,
    );
    items = await repository.watchIncomes().first;
    final updated = items.firstWhere((item) => item.id == created.id);
    expect(updated.title, 'Consulting Updated');
    expect(updated.amountKes, 2200);

    await repository.deleteIncome(created.id);
    items = await repository.watchIncomes().first;
    expect(items.where((item) => item.id == created.id), isEmpty);
  });
}
