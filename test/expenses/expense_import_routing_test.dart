import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
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
    'medium confidence imports land in review queue and can be approved',
    () async {
      final imported = await repository.importSmsMessages(const [
        'AB12CD34EF Confirmed. Ksh300.00 withdrawn at ATM on 8/3/26 at 10:00 AM.',
      ]);

      expect(imported, 0);

      final metrics = await repository.fetchImportMetrics();
      expect(metrics.reviewQueueCount, 1);

      final reviewItems = await repository.fetchReviewQueue();
      expect(reviewItems, isNotEmpty);

      await repository.resolveReviewItem(
        reviewId: reviewItems.first.id,
        approve: true,
      );

      final updatedMetrics = await repository.fetchImportMetrics();
      expect(updatedMetrics.reviewQueueCount, 0);

      final snapshot = await repository.watchSnapshot().first;
      expect(snapshot.transactions.any((tx) => tx.amountKes == 300.0), isTrue);
    },
  );

  test('low confidence imports are quarantined and can be dismissed', () async {
    final imported = await repository.importSmsMessages(const [
      'ZZ11YY22XX Confirmed. Ksh50.00 transfer noted on 7/3/26 at 4:00 PM.',
    ]);

    expect(imported, 0);
    final metrics = await repository.fetchImportMetrics();
    expect(metrics.quarantineCount, 1);

    final items = await repository.fetchQuarantineItems();
    expect(items, isNotEmpty);

    await repository.dismissQuarantineItem(items.first.id);

    final updated = await repository.fetchImportMetrics();
    expect(updated.quarantineCount, 0);
  });

  test('audit logs omit raw SMS payloads', () async {
    const rawMessage =
        'QW12ER34TY Confirmed. Ksh250.00 paid to WATER BILL on 8/3/26 at 9:00 AM.';

    await repository.importSmsMessages(const [rawMessage]);

    final rows = await store.executor.runSelect(
      'SELECT payload FROM sms_import_audit ORDER BY id DESC LIMIT 1',
      const [],
    );

    expect(rows, isNotEmpty);
    final payload = '${rows.first['payload'] ?? ''}';
    expect(payload.contains('raw_message'), isFalse);
    expect(payload.contains('WATER BILL'), isFalse);
    expect(payload.contains('QW12ER34TY'), isFalse);
  });

  test('duplicate SMS does not create duplicate ledger rows', () async {
    const message =
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.';

    await repository.importSmsMessages(const [message, message]);

    final snapshot = await repository.watchSnapshot().first;
    final matching = snapshot.transactions
        .where((tx) => tx.amountKes == 1250 && tx.title == 'Sky Cafe')
        .length;

    expect(matching, 1);
  });
}
