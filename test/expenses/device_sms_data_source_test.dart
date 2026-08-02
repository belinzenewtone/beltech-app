import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

SmsQueryRunner _runnerOnce(List<SmsMessage> messages) {
  return (SmsQuery query, {int start = 0, int count = 200}) async =>
      start == 0 ? messages : const <SmsMessage>[];
}

void main() {
  test('returns empty list when platform is not Android', () async {
    final source = DeviceSmsDataSource(
      isAndroid: () => false,
      requestPermission: () async => true,
      queryRunner: _runnerOnce([
        _sms(
          body:
              'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.',
          sender: 'MPESA',
          date: DateTime.now(),
        ),
      ]),
    );

    final result = await source.loadLikelyMpesaMessages();
    expect(result, isEmpty);
  });

  test('filters MPESA-like inbox messages by date window', () async {
    final now = DateTime.now();
    final source = DeviceSmsDataSource(
      isAndroid: () => true,
      requestPermission: () async => true,
      queryRunner: _runnerOnce([
        _sms(
          body:
              'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.',
          sender: 'MPESA',
          date: now.subtract(const Duration(hours: 2)),
        ),
        _sms(
          body: 'Utility reminder only.',
          sender: 'Service',
          date: now.subtract(const Duration(hours: 1)),
        ),
        _sms(
          body:
              'RT98TT77ZA Confirmed. Ksh200.00 paid to TOKENS on 1/1/26 at 8:00 PM.',
          sender: 'MPESA',
          date: now.subtract(const Duration(days: 5)),
        ),
      ]),
    );

    final result = await source.loadLikelyMpesaMessages(
      from: now.subtract(const Duration(days: 1)),
    );
    expect(result.length, 1);
    expect(result.single.toLowerCase(), contains('confirmed'));
  });

  test('returns timestamped inbox entries for parser fallback', () async {
    final now = DateTime.now();
    final source = DeviceSmsDataSource(
      isAndroid: () => true,
      requestPermission: () async => true,
      queryRunner: _runnerOnce([
        _sms(
          body: 'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN sometime.',
          sender: 'MPESA',
          date: now.subtract(const Duration(minutes: 10)),
        ),
      ]),
    );

    final entries = await source.loadLikelyMpesaEntries();
    expect(entries.length, 1);
    expect(entries.single.body, contains('Confirmed'));
    expect(entries.single.receivedAt, isNotNull);
  });

  test('filters Fuliza notice noise even when sender is MPESA', () async {
    final source = DeviceSmsDataSource(
      isAndroid: () => true,
      requestPermission: () async => true,
      queryRunner: _runnerOnce([
        _sms(
          body:
              'Dear customer, Fuliza M-PESA limit update: your available balance is Ksh1,200.00. Dial *234# for details.',
          sender: 'MPESA',
          date: DateTime.now(),
        ),
      ]),
    );

    final entries = await source.loadLikelyMpesaEntries();
    expect(entries, isEmpty);
  });

  // Kotlin-parity import filter: M-Pesa only / Banks only / both.
  group('ImportSourceFilter', () {
    DeviceSmsDataSource sourceWith() => DeviceSmsDataSource(
      isAndroid: () => true,
      requestPermission: () async => true,
      queryRunner: _runnerOnce([
        _sms(
          body: 'QW12AB34CD Confirmed. Ksh500.00 sent to SHOP on 7/3/26 at 6PM.',
          sender: 'MPESA',
          date: DateTime.now(),
        ),
        _sms(
          body: 'Dear Customer, your KCB account has been debited with KES 1,200.00.',
          sender: 'KCB',
          date: DateTime.now(),
        ),
      ]),
    );

    test('both includes M-Pesa and bank', () async {
      final e = await sourceWith().loadLikelyMpesaEntries(
        filter: ImportSourceFilter.both,
      );
      expect(e.length, 2);
    });

    test('mpesa includes only the M-Pesa message', () async {
      final e = await sourceWith().loadLikelyMpesaEntries(
        filter: ImportSourceFilter.mpesa,
      );
      expect(e.length, 1);
      expect(e.single.sender, 'MPESA');
    });

    test('banks includes only the bank message', () async {
      final e = await sourceWith().loadLikelyMpesaEntries(
        filter: ImportSourceFilter.banks,
      );
      expect(e.length, 1);
      expect(e.single.sender, 'KCB');
    });
  });
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
