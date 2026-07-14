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

  // ── Airtime primary rules (Phase 6 regression) ───────────────────────────
  //
  // These tests guard against the regression where airtime was classified as
  // a Phase 2 fallback (MEDIUM) and sent-for-airtime misclassified as sent.
  // Both primary rules must fire at HIGH confidence from MPESA sender.

  group('airtime primary rules — Phase 6 regression guard', () {
    test('bought format → airtime type, HIGH, directLedger', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. You bought Ksh50.00 of Airtime on 14/7/26 at 10:00 AM.'
        ' New M-PESA balance is Ksh450.00. Transaction cost, Ksh0.00.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.airtime);
      expect(r.confidence, MpesaConfidence.high);
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('bought format without "You" prefix → airtime', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Bought Ksh100.00 of Airtime on 14/7/26 at 9:00 AM.'
        ' New M-PESA balance is Ksh900.00.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.airtime);
      expect(r.confidence, MpesaConfidence.high);
    });

    test('sent-for-airtime format → airtime (not sent), HIGH, directLedger', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh50.00 sent to 0712345678 for airtime on 14/7/26 at 10:00 AM.'
        ' New M-PESA balance is Ksh450.00.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.airtime);
      expect(r.transactionType, isNot(MpesaTransactionType.sent));
      expect(r.confidence, MpesaConfidence.high);
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('sent-for-airtime with 254 prefix → airtime', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh30.00 sent to 254712345678 for airtime on 14/7/26 at 9:30 AM.'
        ' New M-PESA balance is Ksh970.00.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.airtime);
    });

    test('airtime category is "Airtime" for both primary rule variants', () {
      final bought = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. You bought Ksh50.00 of Airtime on 1/1/26 at 9:00 AM.',
        sender: 'MPESA',
      );
      final sentFor = parser.parseSingleDetailed(
        'BB22CC33DD Confirmed. Ksh50.00 sent to 0712345678 for airtime on 1/1/26 at 9:00 AM.',
        sender: 'MPESA',
      );
      expect(bought!.category, 'Airtime');
      expect(sentFor!.category, 'Airtime');
    });
  });

  // ── Safaricom shortcode trust list (Phase 6) ──────────────────────────────
  //
  // Safaricom sends some M-Pesa SMS from numeric shortcodes (22625, 21016, 456).
  // Without the allowlist these would be downgraded HIGH→MEDIUM and land in the
  // review queue instead of the direct ledger.

  group('Safaricom shortcode trust list', () {
    const airtimeSms =
        'QW12AB34CD Confirmed. You bought Ksh50.00 of Airtime on 14/7/26 at 10:00 AM.'
        ' New M-PESA balance is Ksh450.00.';

    test('sender 22625 is trusted — no confidence downgrade', () {
      final r = parser.parseSingleDetailed(airtimeSms, sender: '22625');
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.high);
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('sender 21016 is trusted — no confidence downgrade', () {
      final r = parser.parseSingleDetailed(airtimeSms, sender: '21016');
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.high);
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('unknown numeric shortcode still downgrades', () {
      final r = parser.parseSingleDetailed(airtimeSms, sender: '99999');
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.medium);
    });

    test('standard sent message from 22625 is trusted at HIGH', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh500.00 sent to JOHN DOE on 14/7/26 at 10:00 AM.'
        ' New M-PESA balance is Ksh1,500.00.',
        sender: '22625',
      );
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.high);
      expect(r.route, MpesaParseRoute.directLedger);
    });
  });

  // ── Promotional footer stripping (Phase 6) ────────────────────────────────

  group('promotional footer stripping', () {
    test('Safaricom Hustler Fund upsell tail is stripped before parsing', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh500.00 sent to JANE DOE on 14/7/26 at 10:00 AM.'
        ' New M-PESA balance is Ksh1,500.00.'
        ' Hustler Fund is available on *334#. Borrow today!',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.sent);
      expect(r.amountKes, 500.0);
    });

    test('"for more info dial" tail stripped without affecting amount', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh1,000.00 received from EMPLOYER on 14/7/26 at 9:00 AM.'
        ' New M-PESA balance is Ksh5,000.00.'
        ' For more info dial *234# or visit m-pesa.com',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.amountKes, 1000.0);
    });

    test('"download the m-pesa app" tail stripped', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh250.00 paid to NAIVAS on 14/7/26 at 10:00 AM.'
        ' New M-PESA balance is Ksh750.00.'
        ' Download the M-PESA app for exclusive offers.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.buyGoods);
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
