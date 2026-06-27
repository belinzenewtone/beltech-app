import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MpesaParserService();

  group('sender-aware confidence', () {
    const message =
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.';

    test('MPESA sender keeps high confidence', () {
      final r = parser.parseSingleDetailed(message, sender: 'MPESA');
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.high);
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('numeric shortcode sender downgrades confidence', () {
      final r = parser.parseSingleDetailed(message, sender: '12345');
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.medium);
      expect(r.route, MpesaParseRoute.reviewQueue);
    });

    test('bank sender downgrades confidence', () {
      final r = parser.parseSingleDetailed(message, sender: 'KCB');
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.medium);
      expect(r.route, MpesaParseRoute.reviewQueue);
    });

    test('null sender leaves confidence unchanged', () {
      final r = parser.parseSingleDetailed(message);
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.high);
      expect(r.route, MpesaParseRoute.directLedger);
    });
  });

  group('message variant detection', () {
    test('"You have received Ksh..." from MPESA is parsed as received', () {
      final r = parser.parseSingleDetailed(
        'You have received Ksh500.00 from JANE DOE on 7/3/26 at 6:24 PM.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.received);
      expect(r.title, 'Jane Doe');
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('balance notification without transaction keywords is ignored', () {
      final r = parser.parseSingleDetailed(
        'Your M-PESA balance is Ksh3,210.55. Dial *234# for details.',
      );
      expect(r, isNull);
    });
  });

  group('paybill vs buyGoods vs sent', () {
    test('"sent to ... account ..." is paybill', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh1,250.00 sent to KPLC PREPAID account 998877 on 7/3/26 at 6:24 PM.',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.paybill);
      expect(r.paybillAccount, '998877');
    });

    test('"paid to ... acc#..." is paybill', () {
      final r = parser.parseSingleDetailed(
        'BB22CC33DD Confirmed. Ksh2,000.00 paid to DSTV acc#123456 on 7/3/26 at 6:24 PM.',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.paybill);
    });

    test('"paid to ... on ..." without account remains buyGoods', () {
      final r = parser.parseSingleDetailed(
        'CC33DD44EE Confirmed. Ksh800.00 paid to CITY CAFE on 7/3/26 at 6:24 PM.',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.buyGoods);
    });

    test('"sent to ... on ..." without account remains sent', () {
      final r = parser.parseSingleDetailed(
        'DD44EE55FF Confirmed. Ksh500.00 sent to JOHN DOE on 7/3/26 at 6:24 PM.',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.sent);
    });
  });

  group('isolate parsing preserves sender-aware accuracy', () {
    test('parseJobsInIsolate applies sender downgrades', () async {
      const message =
          'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.';
      final jobs = [
        const SmsParseJob(message, sender: '12345'),
        const SmsParseJob(message, sender: 'MPESA'),
      ];

      final results = await MpesaParserService.parseJobsInIsolate(jobs);
      expect(results.length, 2);
      expect(results[0].confidence, MpesaConfidence.medium);
      expect(results[1].confidence, MpesaConfidence.high);
    });
  });
}
