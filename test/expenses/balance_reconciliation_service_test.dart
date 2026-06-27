import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/expenses/domain/services/balance_reconciliation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const {});

  late AppDriftStore store;
  late BalanceReconciliationService service;

  setUp(() {
    store = AppDriftStore();
    service = BalanceReconciliationService(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  Future<void> insertSmsTransaction({
    required double amount,
    required double balanceAfter,
    required DateTime occurredAt,
    required String type,
  }) async {
    await store.addTransaction(
      title: 'Test',
      category: 'Other',
      amountKes: amount,
      occurredAt: occurredAt,
      source: 'sms',
      sourceHash: 'hash-${occurredAt.millisecondsSinceEpoch}',
      transactionType: type,
      balanceAfterKes: balanceAfter,
    );
  }

  test('reconcile returns empty when balances align', () async {
    final base = DateTime(2025, 1, 1, 10, 0);
    await insertSmsTransaction(
      amount: 1000,
      balanceAfter: 9000,
      occurredAt: base,
      type: 'sent',
    );
    await insertSmsTransaction(
      amount: 500,
      balanceAfter: 8500,
      occurredAt: base.add(const Duration(hours: 1)),
      type: 'sent',
    );

    final results = await service.reconcile();
    expect(results.where((r) => r.hasDiscrepancy), isEmpty);
  });

  test('reconcile flags mismatched reported balance', () async {
    final base = DateTime(2025, 1, 1, 10, 0);
    await insertSmsTransaction(
      amount: 1000,
      balanceAfter: 9000,
      occurredAt: base,
      type: 'sent',
    );
    // Reported balance dropped by 1500 but recorded amount is 500.
    await insertSmsTransaction(
      amount: 500,
      balanceAfter: 7500,
      occurredAt: base.add(const Duration(hours: 1)),
      type: 'sent',
    );

    final results = await service.reconcile();
    final discrepancies = results.where((r) => r.hasDiscrepancy).toList();
    expect(discrepancies, hasLength(1));
    expect(discrepancies.first.variance, closeTo(-1000, 0.01));
  });

  test('reconcile ignores non-sms transactions', () async {
    await store.addTransaction(
      title: 'Manual',
      category: 'Other',
      amountKes: 1000,
      occurredAt: DateTime(2025, 1, 1),
    );

    final results = await service.reconcile();
    expect(results, isEmpty);
  });
}
