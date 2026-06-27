import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const {});

  late AppDriftStore store;

  setUp(() {
    store = AppDriftStore();
  });

  tearDown(() async {
    await store.dispose();
  });

  test('importFromDevice creates income records for received payments', () async {
    final receivedAt = DateTime(2025, 11, 22, 9, 30);
    final source = DeviceSmsDataSource(
      isAndroid: () => true,
      requestPermission: () async => true,
      queryRunner: (q, {start = 0, count = 200}) async => start == 0
          ? [
              _sms(
                body:
                    'AA11BB22CC Confirmed. Ksh5,000.00 received from EMPLOYER LTD on 22/11/25 at 9:30 AM. New M-PESA balance is Ksh15,000.00.',
                sender: 'MPESA',
                date: receivedAt,
              ),
            ]
          : const <SmsMessage>[],
    );
    final repoWithDevice = ExpensesRepositoryImpl(
      store,
      const MpesaParserService(),
      null,
      source,
    );

    final imported = await repoWithDevice.importFromDevice();
    expect(imported, 1);

    final incomes = await store.executor.runSelect(
      'SELECT title, amount, received_at, source FROM incomes WHERE source = ?',
      ['sms'],
    );
    expect(incomes, hasLength(1));
    expect('${incomes.first['title']}', 'Employer Ltd');
    expect((incomes.first['amount'] as num).toDouble(), 5000);
  });

  test('duplicate received SMS does not create duplicate income', () async {
    final receivedAt = DateTime(2025, 11, 22, 9, 30);
    final rawMessage =
        'AA11BB22CC Confirmed. Ksh5,000.00 received from EMPLOYER LTD on 22/11/25 at 9:30 AM. New M-PESA balance is Ksh15,000.00.';
    final source = DeviceSmsDataSource(
      isAndroid: () => true,
      requestPermission: () async => true,
      queryRunner: (q, {start = 0, count = 200}) async => start == 0
          ? [_sms(body: rawMessage, sender: 'MPESA', date: receivedAt)]
          : const <SmsMessage>[],
    );
    final repoWithDevice = ExpensesRepositoryImpl(
      store,
      const MpesaParserService(),
      null,
      source,
    );

    await repoWithDevice.importFromDevice();
    await repoWithDevice.importFromDevice();

    final incomes = await store.executor.runSelect(
      'SELECT COUNT(*) AS c FROM incomes WHERE source = ?',
      ['sms'],
    );
    expect((incomes.first['c'] as num).toInt(), 1);
  });
}

SmsMessage _sms({required String body, required String sender, DateTime? date}) {
  return SmsMessage.fromJson({
    'body': body,
    'address': sender,
    'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
  });
}
