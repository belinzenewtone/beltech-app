import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/bills/data/repositories/bills_repository_impl.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late BillsRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = BillsRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('addBill and loadBills persist correctly', () async {
    await repository.upsertBill(
      name: 'Electricity',
      amount: 5000,
      dueDate: DateTime(2024, 6, 15),
      urgency: BillUrgency.high,
    );

    final bills = await repository.loadBills();
    expect(bills.length, 1);
    expect(bills.first.name, 'Electricity');
    expect(bills.first.amount, 5000);
    expect(bills.first.urgency, BillUrgency.high);
    expect(bills.first.paid, false);
  });

  test('updateBill and deleteBill work correctly', () async {
    await repository.upsertBill(
      name: 'Water',
      amount: 1200,
      dueDate: DateTime(2024, 6, 10),
    );

    final created = await repository.loadBills();
    final bill = created.first;

    await repository.updateBill(id: bill.id, paid: true);
    final updated = await repository.loadBills();
    expect(updated.first.paid, true);

    await repository.deleteBill(bill.id);
    final afterDelete = await repository.loadBills();
    expect(afterDelete, isEmpty);
  });

  test('overdueCount returns correct number', () async {
    final now = DateTime.now();
    await repository.upsertBill(
      name: 'Past',
      amount: 1000,
      dueDate: now.subtract(const Duration(days: 5)),
    );
    await repository.upsertBill(
      name: 'Future',
      amount: 2000,
      dueDate: now.add(const Duration(days: 5)),
    );

    final overdue = await repository.overdueCount();
    expect(overdue, 1);
  });
}
