import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const {});

  group('MpesaParserService isolate parsing', () {
    const parser = MpesaParserService();

    const messages = [
      'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM. New M-PESA balance is Ksh3,210.55.',
      'AA12BB34CC Confirmed. Ksh500.00 Fuliza M-PESA amount credited on 8/3/26 at 10:00 AM.',
      'DD56EE78FF Confirmed. Ksh200.00 paid from your Fuliza M-PESA on 8/3/26 at 2:30 PM.',
      'not an mpesa message at all',
    ];

    test('parseJobsInIsolate returns the same candidates as sync parsing', () async {
      final jobs = messages
          .map((m) => SmsParseJob(m))
          .toList(growable: false);

      final isolated = await MpesaParserService.parseJobsInIsolate(jobs);
      final sync = parser.parseManyDetailed(messages);

      expect(isolated.length, sync.length);
      for (var i = 0; i < isolated.length; i++) {
        expect(isolated[i].sourceHash, sync[i].sourceHash);
        expect(isolated[i].transactionType, sync[i].transactionType);
        expect(isolated[i].title, sync[i].title);
        expect(isolated[i].amountKes, sync[i].amountKes);
        expect(isolated[i].route, sync[i].route);
      }
    });

    test('parseJobsInIsolate handles an empty list', () async {
      final result = await MpesaParserService.parseJobsInIsolate(const []);
      expect(result, isEmpty);
    });
  });

  group('ExpensesRepositoryImpl early source-hash dedup', () {
    late AppDriftStore store;
    late ExpensesRepositoryImpl repository;

    setUp(() {
      store = AppDriftStore();
      repository = ExpensesRepositoryImpl(store, const MpesaParserService());
    });

    tearDown(() async {
      await store.dispose();
    });

    test('re-enqueueing the same SMS does not create a second queue row', () async {
      const message =
          'LM11NO22PQ Confirmed. Ksh900.00 sent to CITY MART on 7/3/26 at 6:24 PM.';

      await repository.importSmsMessages([message]);
      await repository.importSmsMessages([message]);

      final rows = await store.executor.runSelect(
        'SELECT COUNT(*) AS c FROM sms_import_queue WHERE source_hash = ?',
        [const MpesaParserService().sourceHash(message)],
      );
      expect(rows.first['c'], 1);
    });

    test('importing an already-ledgered SMS skips enqueue entirely', () async {
      const message =
          'LM11NO22PQ Confirmed. Ksh900.00 sent to CITY MART on 7/3/26 at 6:24 PM.';

      final firstImported = await repository.importSmsMessages([message]);
      expect(firstImported, 1);

      final secondImported = await repository.importSmsMessages([message]);
      expect(secondImported, 0);

      final rows = await store.executor.runSelect(
        'SELECT COUNT(*) AS c FROM transactions WHERE source_hash = ?',
        [const MpesaParserService().sourceHash(message)],
      );
      expect(rows.first['c'], 1);
    });
  });

  group('AppDriftStore SMS batch helpers', () {
    late AppDriftStore store;

    setUp(() {
      store = AppDriftStore();
    });

    tearDown(() async {
      await store.dispose();
    });

    test('addTransactionsBatch inserts multiple rows', () async {
      await store.addTransactionsBatch([
        ['TX 1', 'Food', 100.0, DateTime(2026, 3, 1).millisecondsSinceEpoch, 'sms', 'hash1', 'sent', 900.0],
        ['TX 2', 'Bills', 250.0, DateTime(2026, 3, 2).millisecondsSinceEpoch, 'sms', 'hash2', 'paybill', 650.0],
      ]);

      final rows = await store.executor.runSelect(
        'SELECT COUNT(*) AS c FROM transactions',
        [],
      );
      expect(rows.first['c'], 2);
    });

    test('insertSmsImportQueueBatch inserts multiple rows', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.insertSmsImportQueueBatch([
        ['local', 'raw1', 'hash1', 'sem1', now, 'pending', 'sent', 0.95, now, now],
        ['local', 'raw2', 'hash2', 'sem2', now, 'pending', 'sent', 0.95, now, now],
      ]);

      final rows = await store.executor.runSelect(
        'SELECT COUNT(*) AS c FROM sms_import_queue',
        [],
      );
      expect(rows.first['c'], 2);
    });

    test('updateSmsImportQueueStatusBatch updates status for multiple rows', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.insertSmsImportQueueBatch([
        ['local', 'raw1', 'hash1', 'sem1', now, 'pending', 'sent', 0.95, now, now],
        ['local', 'raw2', 'hash2', 'sem2', now, 'pending', 'sent', 0.95, now, now],
      ]);

      final inserted = await store.executor.runSelect(
        'SELECT id FROM sms_import_queue ORDER BY id',
        [],
      );
      final ids = inserted.map((r) => r['id'] as int).toList();

      await store.updateSmsImportQueueStatusBatch([
        ['done', now, null, ids[0]],
        ['duplicate', now, null, ids[1]],
      ]);

      final rows = await store.executor.runSelect(
        'SELECT status FROM sms_import_queue ORDER BY id',
        [],
      );
      expect(rows[0]['status'], 'done');
      expect(rows[1]['status'], 'duplicate');
    });

    test('insertSmsImportAuditBatch inserts multiple audit rows', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.insertSmsImportAuditBatch([
        ['local', 'hash1', 'sem1', 'sent', 0.95, 'imported', 'done', '{}', now],
        ['local', 'hash2', 'sem2', 'sent', 0.95, 'imported', 'done', '{}', now],
      ]);

      final rows = await store.executor.runSelect(
        'SELECT COUNT(*) AS c FROM sms_import_audit',
        [],
      );
      expect(rows.first['c'], 2);
    });

    test('insertSmsReviewBatch and insertSmsQuarantineBatch insert rows', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.insertSmsReviewBatch([
        ['local', 'hash1', 'sem1', 'Merchant', 'Food', 100.0, now, 'raw1', 0.7, 'pending', now],
      ]);
      await store.insertSmsQuarantineBatch([
        ['local', 'hash2', 'sem2', 'raw2', 'low confidence', 0.3, 'pending', now],
      ]);

      final review = await store.executor.runSelect(
        'SELECT COUNT(*) AS c FROM sms_review_queue',
        [],
      );
      final quarantine = await store.executor.runSelect(
        'SELECT COUNT(*) AS c FROM sms_quarantine',
        [],
      );
      expect(review.first['c'], 1);
      expect(quarantine.first['c'], 1);
    });
  });
}
