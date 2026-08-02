// Phase P5 — Airtel Money parsing (new provider), routed through the shared
// MpesaParserService so it flows the same dedup/route/persist pipeline.

import 'package:beltech/features/expenses/data/services/airtel_money_parser.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MpesaParserService();
  const airtel = AirtelMoneyParser();

  group('AirtelMoneyParser', () {
    test('received', () {
      final r = airtel.tryParse(
        'Airtel Money: You have received KES 500.00 from JOHN DOE 0733111222. '
        'Transaction ID: AIR12345678. New balance is KES 1,200.00.',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.received);
      expect(r.amountKes, 500.0);
      expect(r.balanceAfterKes, 1200.0);
      expect(r.counterparty?.toUpperCase(), contains('JOHN'));
      expect(r.mpesaCode, 'AIR12345678');
      expect(r.confidence, MpesaConfidence.high);
    });

    test('sent with charges', () {
      final r = airtel.tryParse(
        'Airtel Money: You have sent KES 200.00 to JANE DOE 0733999888. '
        'Transaction ID: AIR87654321. Balance KES 800.00. Charges: KES 12.00.',
      );
      expect(r!.transactionType, MpesaTransactionType.sent);
      expect(r.amountKes, 200.0);
      expect(r.feeKes, 12.0);
      expect(r.counterparty?.toUpperCase(), contains('JANE'));
    });

    test('withdrawal', () {
      final r = airtel.tryParse(
        'Airtel Money: You have withdrawn KES 1,000.00 from Agent 55555. '
        'Transaction ID: AIR11223344. Balance is KES 300.00.',
      );
      expect(r!.transactionType, MpesaTransactionType.withdrawal);
      expect(r.amountKes, 1000.0);
    });

    test('airtime', () {
      final r = airtel.tryParse(
        'Airtel Money: You have bought airtime of KES 50.00. '
        'Transaction ID: AIR99887766. Balance KES 250.00.',
      );
      expect(r!.transactionType, MpesaTransactionType.airtime);
      expect(r.amountKes, 50.0);
    });

    test('does not claim M-Pesa or bank messages', () {
      expect(
        airtel.canParse(
          'SIE8QWE123 Confirmed. You have received Ksh390.00 from JOHN DOE '
          '0712345678 on 16/3/26. New M-PESA balance is Ksh1,200.00.',
        ),
        isFalse,
      );
      expect(
        airtel.canParse('Ksh1,250.00 paid to NAIROBI WATER for account 998877'),
        isFalse,
        reason: '"NAIROBI" contains the substring AIR but is not Airtel',
      );
      // Audit regression: a BANK SMS naming an Airtel biller must NOT be stolen
      // by the Airtel-first dispatch (bare "airtel" keyword used to match).
      expect(
        airtel.canParse(
          'KCB: You have paid KES 500.00 to AIRTEL SHOP. Ref ABC123.',
          sender: 'KCB',
        ),
        isFalse,
        reason: 'bank payment to an Airtel biller is not an Airtel Money SMS',
      );
    });
  });

  group('routing through MpesaParserService', () {
    test('an Airtel SMS is parsed as Airtel, not misread as M-Pesa', () {
      final r = parser.parseSingleDetailed(
        'Airtel Money: You have received KES 750.00 from PETER K 0733222333. '
        'Transaction ID: AIR55667788. New balance is KES 2,000.00.',
      );
      expect(r, isNotNull);
      expect(r!.reason, 'Airtel Money');
      expect(r.transactionType, MpesaTransactionType.received);
      expect(r.amountKes, 750.0);
    });

    test('sender-based detection still works with a numeric-looking body', () {
      final r = parser.parseSingleDetailed(
        'You have sent KES 300.00 to SHOP 254. Txn ID: AIR44001122. '
        'Balance KES 100.00.',
        sender: 'AIRTEL',
      );
      expect(r!.reason, 'Airtel Money');
      expect(r.amountKes, 300.0);
    });
  });
}
