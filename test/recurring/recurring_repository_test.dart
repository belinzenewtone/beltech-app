import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late RecurringRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = RecurringRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('materializeDue creates concrete records', () async {
    await repository.addTemplate(
      kind: RecurringKind.expense,
      title: 'Monthly Rent',
      category: 'Bills',
      amountKes: 25000,
      cadence: RecurringCadence.monthly,
      nextRunAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    final before = await store.executor
        .runSelect('SELECT COUNT(*) AS total FROM transactions', const []);
    final beforeCount = (before.first['total'] as num?)?.toInt() ?? 0;

    final generated = await repository.materializeDue();
    expect(generated, greaterThanOrEqualTo(1));

    final after = await store.executor
        .runSelect('SELECT COUNT(*) AS total FROM transactions', const []);
    final afterCount = (after.first['total'] as num?)?.toInt() ?? 0;
    expect(afterCount, greaterThan(beforeCount));
  });
}
