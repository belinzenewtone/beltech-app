// Regression tests from the real-device SMS mining corpus (Phase P7).
//
// These are real M-Pesa / LOOP / I&M / PesaLink / Equity messages pulled from
// the device inbox. They pin the parser improvements made after the mining
// session so they can't silently regress.

import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MpesaParserService();

  group('real-corpus: M-Pesa variants', () {
    test('Confirmed.on ... PMWithdraw format parses as withdrawal', () {
      final r = parser.parseSingleDetailed(
        'UGHDL01LT0 Confirmed.on 17/7/26 at 4:37 PMWithdraw Ksh500.00 from 2059881 - JAMBU COMTECH Baraka shopKasarani New M-PESA balance is Ksh2,320.38. Transaction cost, Ksh29.00.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.withdrawal);
      expect(r.route, MpesaParseRoute.directLedger);
      expect(r.amountKes, closeTo(500.0, 0.01));
      expect(r.balanceAfterKes, closeTo(2320.38, 0.01));
    });

    test('failed transaction is ignored (null)', () {
      final r = parser.parseSingleDetailed(
        'Failed. Insufficient funds in your M-PESA account as well as Fuliza M-PESA to send KSH50.00. Your M-PESA balance KSH0.00. Available Fuliza M-PESA limit KSH33.56.',
        sender: 'MPESA',
      );
      expect(r, isNull);
    });

    test('wrong-PIN failure is ignored', () {
      final r = parser.parseSingleDetailed(
        'Failed, you have entered the wrong PIN. If forgotten please dial *334#, select My Account, select M-PESA PIN Manager then M-PESA Forgot PIN and follow the prompts.',
        sender: 'MPESA',
      );
      expect(r, isNull);
    });

    test('balance-only notice is ignored', () {
      final r = parser.parseSingleDetailed(
        'UB6DL632FM Confirmed. Your account balance was: M-PESA Account : Ksh0.00 Business Account : Ksh0.00 on 6/2/26 at 5:19 PM. Transaction cost, Ksh0.00. Start Investing today with Ziidi MMF & earn daily. Dial *334#',
        sender: 'MPESA',
      );
      expect(r, isNull);
    });

    test('Fuliza limit summary parses as fulizaCharge', () {
      final r = parser.parseSingleDetailed(
        'Dear BELINZE, your Fuliza M-PESA limit is Ksh 900.00. You have an outstanding amount of Ksh 799.89 due on 25/10/25. Transaction Cost Ksh 0.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.fulizaCharge);
      expect(r.route, MpesaParseRoute.directLedger);
      expect(r.fulizaAvailableLimitKes, closeTo(900.0, 0.01));
      expect(r.fulizaOutstandingKes, closeTo(799.89, 0.01));
    });

    test('Fuliza charge notice (access fee) parses as fulizaCharge', () {
      final r = parser.parseSingleDetailed(
        'UGVDL1O5UV Confirmed. Fuliza M-PESA amount is Ksh 20.00. Access Fee charged Ksh 0.20. Total Fuliza M-PESA outstanding amount is Ksh102.06 due on 30/08/26.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.fulizaCharge);
      expect(r.fulizaOutstandingKes, closeTo(102.06, 0.01));
    });

    test('Fuliza charge notice (interest, older template) parses', () {
      final r = parser.parseSingleDetailed(
        'TGI4HPX4PK Confirmed. Fuliza M-PESA amount is Ksh 100.00. Interest charged Ksh 1.00. Total Fuliza M-PESA outstanding amount is Ksh 724.62 due on 14/08/25.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.fulizaCharge);
      expect(r.fulizaOutstandingKes, closeTo(724.62, 0.01));
    });

    test('Fuliza partial repayment parses as fulizaRepayment', () {
      final r = parser.parseSingleDetailed(
        'Confirmed. Ksh 250.00 from your M-PESA has been used to partially pay your outstanding Fuliza M-PESA. Your available Fuliza M-PESA limit is Ksh 263.56. Your M-PESA balance is 0.00.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.fulizaRepayment);
      expect(r.route, MpesaParseRoute.directLedger);
      expect(r.amountKes, closeTo(250.0, 0.01));
      expect(r.fulizaAvailableLimitKes, closeTo(263.56, 0.01));
    });

    test('Fuliza full repayment parses as fulizaRepayment', () {
      final r = parser.parseSingleDetailed(
        'Confirmed. Ksh 102.06 from your M-PESA has been used to fully pay your outstanding Fuliza M-PESA. Available Fuliza M-PESA limit is Ksh 900.00. Your M-PESA balance is 147.94.',
        sender: 'MPESA',
      );
      expect(r, isNotNull);
      expect(r!.transactionType, MpesaTransactionType.fulizaRepayment);
      expect(r.fulizaAvailableLimitKes, closeTo(900.0, 0.01));
      expect(r.balanceAfterKes, closeTo(147.94, 0.01));
    });

    test('business-to-M-PESA transfer is ignored (internal)', () {
      final r = parser.parseSingleDetailed(
        'SJI3IZVLYT Confirmed, Ksh1,600.00 has been moved from your business account to your M-PESA account on 18/10/24 at 3:18 PM.. New business balance is Ksh0.00. New M-PESA balance is Ksh1,600.00.',
        sender: 'MPESA',
      );
      expect(r, isNull);
    });
  });

  group('real-corpus: bank senders', () {
    test('LOOP send parses as bank transaction with amount', () {
      final r = parser.parseSingleDetailed(
        'You have successfully sent KES 400.00 to 0706483760 - Muga Grace Abida. Fee:KES.5.75. LOOP Ref NHEUMBS6RZLG, M-Pesa Ref, UH2BA1KS2V on 02/08/2026 17:25:08.',
        sender: 'LOOP',
      );
      expect(r, isNotNull);
      expect(r!.amountKes, closeTo(400.0, 0.01));
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('I&M own-account transfer is ambiguous → review', () {
      final r = parser.parseSingleDetailed(
        'Transfer to Own Account of KES 1,000.00 to A/c 01705080913050 on 01/08/2026 11:29 processed successfully. Transaction Ref ID: 410425977499.',
        sender: 'IANDMBANK',
      );
      expect(r, isNotNull);
      expect(r!.amountKes, closeTo(1000.0, 0.01));
      expect(r.route, MpesaParseRoute.reviewQueue);
    });

    test('PesaLink received parses (no date → review)', () {
      final r = parser.parseSingleDetailed(
        'KES 2,500 received from BELINZE OJING into A/C ****6150. TUMA DIRECT na Pesalink. Ambia HR atume salo Direct from bank, 24/7, NO CUT-OFF. Download receipt here: https://r.pesalink.co.ke/r1=76w7ExVt',
        sender: 'PESALINK',
      );
      expect(r, isNotNull);
      expect(r!.amountKes, closeTo(2500.0, 0.01));
      expect(r.route, MpesaParseRoute.reviewQueue);
    });

    test('LOOP card auth hold (KES 0.00) is ignored', () {
      final r = parser.parseSingleDetailed(
        'BELINZE, Online transaction of KES.0.00 has been approved on your card ending **0553 at GOOGLE *TEMPORARY HOLD on 02/08/2026 11:22:37. If it is not yours, please call Loop 0730 714444/0709 714444 urgently.',
        sender: 'LOOP',
      );
      expect(r, isNull);
    });

    test('Equity OTP is ignored', () {
      final r = parser.parseSingleDetailed(
        'Never share this code with anyone, including us. Use code 082017 to send 50.00 KES to  254722445950 via MPesa.',
        sender: 'EquityBank',
      );
      expect(r, isNull);
    });

    test('Equity airtime purchase parses with reversed amount', () {
      final r = parser.parseSingleDetailed(
        'Your airtime purchase of 50 KES for Safaricom 254724807586 was successful. Ref. A908899BD8AB2 on 31 Mar 2025 at 19:04 EAT. Charges 0 KES',
        sender: 'EquityBank',
      );
      expect(r, isNotNull);
      expect(r!.amountKes, closeTo(50.0, 0.01));
    });

    test('Equity payment parses with reversed amount', () {
      final r = parser.parseSingleDetailed(
        'Your payment of 270 KES to SAMUEL MAINA 0723853033 was successful. Ref. AC8C5B6D1B147 on 11/04/2025 at 13:58. Charges 0 KES',
        sender: 'EquityBank',
      );
      expect(r, isNotNull);
      expect(r!.amountKes, closeTo(270.0, 0.01));
    });

    test('Equity credited-to-M-PESA parses as bank transfer', () {
      final r = parser.parseSingleDetailed(
        'Your transaction of Kshs. 300.0  has been credited to  254724807586  BELINZE NEWTONE OJING. Ref.  EQABB6BC4E0B19D. MPESA Ref.  SL62FVV2H6 on  06/12/2024 at 13:54:37.',
        sender: 'EquityBank',
      );
      expect(r, isNotNull);
      expect(r!.amountKes, closeTo(300.0, 0.01));
    });
  });
}
