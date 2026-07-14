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

  test('searchMerchantRegistry returns learned merchants', () async {
    await repository.addManualTransaction(
      title: 'Sky Cafe',
      category: 'Food & Dining',
      amountKes: 250,
    );
    await repository.addManualTransaction(
      title: 'KPLC',
      category: 'Utilities',
      amountKes: 1000,
    );

    final results = await repository.searchMerchantRegistry('sky');
    expect(results, isNotEmpty);
    expect(results.first.merchantKey.toLowerCase(), contains('sky'));
    expect(results.first.category, 'Food & Dining');
  });

  test('fetchTopMerchants orders by usage count', () async {
    await repository.addManualTransaction(
      title: 'Sky Cafe',
      category: 'Food & Dining',
      amountKes: 250,
    );
    await repository.addManualTransaction(
      title: 'Sky Cafe',
      category: 'Food & Dining',
      amountKes: 300,
    );
    await repository.addManualTransaction(
      title: 'KPLC',
      category: 'Utilities',
      amountKes: 1000,
    );

    final results = await repository.fetchTopMerchants(limit: 10);
    expect(results.first.merchantKey.toLowerCase(), contains('sky'));
    expect(results.first.usageCount, 2);
  });

  test('getMerchantRegistryEntry returns matching category', () async {
    await repository.addManualTransaction(
      title: 'Sky Cafe',
      category: 'Food & Dining',
      amountKes: 250,
    );

    final entry = await repository.getMerchantRegistryEntry('Sky Cafe');
    expect(entry, isNotNull);
    expect(entry!.category, 'Food & Dining');
  });

  test('getMerchantRegistryEntry returns null for unknown merchant', () async {
    final entry = await repository.getMerchantRegistryEntry('Unknown Ltd');
    expect(entry, isNull);
  });
}
