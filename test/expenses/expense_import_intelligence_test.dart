import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDriftStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    store = AppDriftStore();
  });

  tearDown(() async {
    await store.dispose();
  });

  test('paybill registry and fuliza lifecycle are tracked after import',
      () async {
    final repository =
        ExpensesRepositoryImpl(store, const MpesaParserService());

    await repository.importSmsMessages(const [
      'QW12AB34CD Confirmed. Ksh1,250.00 sent to KPLC PREPAID for account 998877 on 7/3/26 at 6:24 PM.',
      'AA12BB34CC Confirmed. Ksh500.00 Fuliza M-PESA amount credited on 8/3/26 at 10:00 AM.',
      'DD56EE78FF Confirmed. Ksh200.00 paid from your Fuliza M-PESA on 8/3/26 at 2:30 PM.',
    ]);

    final paybills = await repository.fetchPaybillProfiles();
    final fuliza = await repository.fetchFulizaLifecycle();

    expect(paybills, isNotEmpty);
    expect(paybills.first.displayName, 'Kplc Prepaid');
    expect(paybills.first.paybill, '998877');
    expect(fuliza.length, 2);
    expect(fuliza.any((item) => item.kind == FulizaLifecycleKind.draw), isTrue);
    expect(
      fuliza.any((item) => item.kind == FulizaLifecycleKind.repayment),
      isTrue,
    );
  });

  test('replay import queue retries previously failed rows', () async {
    final repository = ExpensesRepositoryImpl(
      store,
      const MpesaParserService(),
      _FlakyMerchantLearningService(),
    );

    await repository.importSmsMessages(const [
      'ZX12CV34BN Confirmed. Ksh350.00 sent to SKY MART on 8/3/26 at 8:10 AM.',
    ]);

    final initialMetrics = await repository.fetchImportMetrics();
    expect(initialMetrics.retryQueueCount, 1);
    expect(initialMetrics.failedQueueCount, 0);

    final replayed = await repository.replayImportQueue();

    expect(replayed, 1);
    final updatedMetrics = await repository.fetchImportMetrics();
    expect(updatedMetrics.retryQueueCount, 0);
    final snapshot = await repository.watchSnapshot().first;
    expect(snapshot.transactions.any((item) => item.amountKes == 350), isTrue);
  });
}

class _FlakyMerchantLearningService extends MerchantLearningService {
  bool _failedOnce = false;

  @override
  Future<String> resolveCategory({
    required String merchantTitle,
    required String fallbackCategory,
  }) async {
    if (!_failedOnce) {
      _failedOnce = true;
      throw Exception('temporary merchant learning failure');
    }
    return fallbackCategory;
  }

  @override
  Future<void> learn({
    required String merchantTitle,
    required String category,
  }) async {}
}
