import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const {});

  late AppDriftStore store;
  late ExpensesRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = ExpensesRepositoryImpl(store, const MpesaParserService());
  });

  tearDown(() async {
    await store.dispose();
  });

  test(
    'addManualTransaction updates snapshot totals and transactions',
    () async {
      final initial = await repository.watchSnapshot().first;
      final nextSnapshot = repository.watchSnapshot().firstWhere(
        (snapshot) =>
            snapshot.transactions.any((tx) => tx.title == 'Test Expense'),
      );

      await repository.addManualTransaction(
        title: 'Test Expense',
        category: 'Other',
        amountKes: 250,
      );

      final updated = await nextSnapshot.timeout(const Duration(seconds: 2));
      expect(updated.weekKes, greaterThanOrEqualTo(initial.weekKes));
      expect(
        updated.transactions.any((tx) => tx.title == 'Test Expense'),
        isTrue,
      );
    },
  );

  test('importSmsMessages parses valid mpesa rows', () async {
    final nextSnapshot = repository.watchSnapshot().firstWhere(
      (snapshot) =>
          snapshot.transactions.any((tx) => tx.title.contains('Sky Cafe')),
    );
    final imported = await repository.importSmsMessages([
      'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM. New M-PESA balance is Ksh3,210.55.',
      'invalid row',
    ]);

    final updated = await nextSnapshot.timeout(const Duration(seconds: 2));
    expect(imported, 1);
    final importedTx = updated.transactions.firstWhere(
      (tx) => tx.title.contains('Sky Cafe'),
    );
    expect(importedTx.balanceAfterKes, 3210.55);
    final rows = await store.executor.runSelect(
      'SELECT transaction_type, source FROM transactions WHERE id = ? LIMIT 1',
      [importedTx.id],
    );
    expect(rows, isNotEmpty);
    expect('${rows.first['transaction_type'] ?? ''}', 'sent');
    expect('${rows.first['source'] ?? ''}', 'sms');
  });

  test(
    'importFromDevice uses SMS receive timestamp when message has no date',
    () async {
      final smsAt = DateTime(2025, 11, 22, 9, 30);
      final source = DeviceSmsDataSource(
        isAndroid: () => true,
        requestPermission: () async => true,
        queryRunner: (q, {start = 0, count = 200}) async => start == 0
            ? [
                _sms(
                  body:
                      'AA11BB22CC Confirmed. Ksh120.00 sent to SKY CAFE sometime.',
                  sender: 'MPESA',
                  date: smsAt,
                ),
              ]
            : const <SmsMessage>[]
      );
      final repoWithDevice = ExpensesRepositoryImpl(
        store,
        const MpesaParserService(),
        null,
        source,
      );

      final imported = await repoWithDevice.importFromDevice();
      expect(imported, 1);

      final rows = await store.executor.runSelect(
        'SELECT occurred_at FROM transactions WHERE source = ? ORDER BY id DESC LIMIT 1',
        ['sms'],
      );
      expect(rows, isNotEmpty);
      expect(rows.first['occurred_at'], smsAt.millisecondsSinceEpoch);
    },
  );

  test(
    'updateTransaction and deleteTransaction persist expense changes',
    () async {
      await repository.addManualTransaction(
        title: 'Expense CRUD',
        category: 'Other',
        amountKes: 99,
        occurredAt: DateTime.now(),
      );

      final created = await repository.watchSnapshot().firstWhere(
        (snapshot) =>
            snapshot.transactions.any((tx) => tx.title == 'Expense CRUD'),
      );
      final tx = created.transactions.firstWhere(
        (item) => item.title == 'Expense CRUD',
      );

      await repository.updateTransaction(
        transactionId: tx.id,
        title: 'Expense CRUD Updated',
        category: 'Food',
        amountKes: 150,
        occurredAt: tx.occurredAt,
      );

      final updated = await repository.watchSnapshot().firstWhere(
        (snapshot) => snapshot.transactions.any(
          (item) => item.id == tx.id && item.title == 'Expense CRUD Updated',
        ),
      );
      expect(
        updated.transactions.any(
          (item) => item.id == tx.id && item.category == 'Food',
        ),
        isTrue,
      );

      await repository.deleteTransaction(tx.id);
      final afterDelete = await repository.watchSnapshot().firstWhere(
        (snapshot) => !snapshot.transactions.any((item) => item.id == tx.id),
      );
      expect(afterDelete.transactions.any((item) => item.id == tx.id), isFalse);
    },
  );

  test('merchant_categories learning is applied to future SMS imports', () async {
    await repository.addManualTransaction(
      title: 'Sky Cafe',
      category: 'Transport',
      amountKes: 250,
    );

    final imported = await repository.importSmsMessages([
      'ZX11CV22BN Confirmed. Ksh500.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.',
    ]);
    expect(imported, 1);

    final learnedRows = await store.executor.runSelect(
      'SELECT category FROM merchant_categories WHERE merchant_key = ? LIMIT 1',
      ['sky cafe'],
    );
    expect(learnedRows, isNotEmpty);
    expect('${learnedRows.first['category'] ?? ''}', 'Transport');

    final txRows = await store.executor.runSelect(
      'SELECT category FROM transactions WHERE source = ? AND LOWER(title) = ? ORDER BY id DESC LIMIT 1',
      ['sms', 'sky cafe'],
    );
    expect(txRows, isNotEmpty);
    expect('${txRows.first['category'] ?? ''}', 'Transport');
  });

  test('category inference overrides type-based fallback for known merchants', () async {
    final imported = await repository.importSmsMessages([
      'BB22CC33DD Confirmed. Ksh2,500.00 paid to SHELL KILIMANI on 7/3/26 at 9:00 AM.',
    ]);
    expect(imported, 1);

    final txRows = await store.executor.runSelect(
      'SELECT category FROM transactions WHERE source = ? AND LOWER(title) LIKE ?',
      ['sms', '%shell%'],
    );
    expect(txRows, isNotEmpty);
    expect('${txRows.first['category'] ?? ''}', 'Transport');
  });

  test('updateTransaction learns corrected category for future imports', () async {
    await repository.addManualTransaction(
      title: 'Java House',
      category: 'Food & Dining',
      amountKes: 800,
    );

    final imported = await repository.importSmsMessages([
      'CC33DD44EE Confirmed. Ksh1,200.00 paid to JAVA HOUSE on 7/3/26 at 10:00 AM.',
    ]);
    expect(imported, 1);

    final txRows = await store.executor.runSelect(
      'SELECT category FROM transactions WHERE source = ? AND LOWER(title) = ?',
      ['sms', 'java house'],
    );
    expect(txRows, isNotEmpty);
    expect('${txRows.first['category'] ?? ''}', 'Food & Dining');
  });

  test('fuzzy dedupe skips same-day near-amount duplicate imports', () async {
    final imported = await repository.importSmsMessages([
      'AA11BB22CC Confirmed. Ksh1000.00 sent to ACME SHOP on 7/3/26 at 8:00 AM.',
      'DD33EE44FF Confirmed. Ksh1000.50 sent to ACME SHOP on 7/3/26 at 9:30 AM.',
    ]);

    expect(imported, 1);
    final rows = await store.executor.runSelect(
      'SELECT COUNT(*) AS total FROM transactions WHERE source = ? AND LOWER(title) = ?',
      ['sms', 'acme shop'],
    );
    expect(rows, isNotEmpty);
    expect(rows.first['total'], 1);
  });

  test(
    're-importing same SMS revives retry queue rows for immediate processing',
    () async {
      final flaky = _FailsOnceMerchantLearningService();
      final firstPass = ExpensesRepositoryImpl(
        store,
        const MpesaParserService(),
        flaky,
      );
      const message =
          'LM11NO22PQ Confirmed. Ksh900.00 sent to CITY MART on 7/3/26 at 6:24 PM.';

      final importedFirst = await firstPass.importSmsMessages([message]);
      expect(importedFirst, 0);

      final retryRows = await store.executor.runSelect(
        'SELECT status, next_retry_at FROM sms_import_queue WHERE source_hash = ? LIMIT 1',
        [const MpesaParserService().sourceHash(message)],
      );
      expect(retryRows, isNotEmpty);
      expect('${retryRows.first['status'] ?? ''}', 'retry');
      expect(retryRows.first['next_retry_at'], isNotNull);

      final secondPass = ExpensesRepositoryImpl(
        store,
        const MpesaParserService(),
      );
      final importedSecond = await secondPass.importSmsMessages([message]);

      expect(importedSecond, 1);
      final txRows = await store.executor.runSelect(
        'SELECT COUNT(*) AS total FROM transactions WHERE LOWER(title) = ? AND amount = ?',
        ['city mart', 900.0],
      );
      expect(txRows, isNotEmpty);
      expect(txRows.first['total'], 1);
    },
  );
}

class _FailsOnceMerchantLearningService extends MerchantLearningService {
  bool _hasFailed = false;

  @override
  Future<String> resolveCategory({
    required String merchantTitle,
    required String fallbackCategory,
  }) async {
    if (!_hasFailed) {
      _hasFailed = true;
      throw Exception('transient merchant learning outage');
    }
    return fallbackCategory;
  }

  @override
  Future<void> learn({
    required String merchantTitle,
    required String category,
  }) async {}
}

SmsMessage _sms({
  required String body,
  required String sender,
  required DateTime date,
}) {
  return SmsMessage.fromJson({
    '_id': date.millisecondsSinceEpoch,
    'thread_id': 1,
    'address': sender,
    'body': body,
    'read': 1,
    'date': date.millisecondsSinceEpoch,
    'sub_id': 1,
  });
}
