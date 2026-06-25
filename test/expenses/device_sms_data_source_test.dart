import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns empty list when platform is not Android', () async {
    final source = DeviceSmsDataSource(
      isAndroid: () => false,
      requestPermission: () async => true,
      queryRunner: (_) async => [
        _sms(
          body:
              'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.',
          sender: 'MPESA',
          date: DateTime.now(),
        ),
      ],
    );

    final result = await source.loadLikelyMpesaMessages();
    expect(result, isEmpty);
  });

  test('filters MPESA-like inbox messages by date window', () async {
    final now = DateTime.now();
    final source = DeviceSmsDataSource(
      isAndroid: () => true,
      requestPermission: () async => true,
      queryRunner: (_) async => [
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
      ],
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
      queryRunner: (_) async => [
        _sms(
          body: 'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN sometime.',
          sender: 'MPESA',
          date: now.subtract(const Duration(minutes: 10)),
        ),
      ],
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
      queryRunner: (_) async => [
        _sms(
          body:
              'Dear customer, Fuliza M-PESA limit update: your available balance is Ksh1,200.00. Dial *234# for details.',
          sender: 'MPESA',
          date: DateTime.now(),
        ),
      ],
    );

    final entries = await source.loadLikelyMpesaEntries();
    expect(entries, isEmpty);
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
