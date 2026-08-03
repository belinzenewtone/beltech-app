// Quick real-message verification against the current parser.
// Run: dart run tool/verify_samples.dart

import 'package:beltech/features/expenses/data/services/generic_bank_parser.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';

void main() {
  const parser = MpesaParserService();

  final samples = <({String sender, String body})>[
    (
      sender: 'LOOP',
      body:
          'You have successfully sent KES 400.00 to 0706483760 - Muga Grace Abida. Fee:KES.5.75. LOOP Ref NHEUMBS6RZLG, M-Pesa Ref, UH2BA1KS2V on 02/08/2026 17:25:08.',
    ),
    (
      sender: 'IANDMBANK',
      body:
          'Transfer to Own Account of KES 1,000.00 to A/c 01705080913050 on 01/08/2026 11:29 processed successfully. Transaction Ref ID: 410425977499.',
    ),
    (
      sender: 'PESALINK',
      body:
          'KES 2,500 received from BELINZE OJING into A/C ****6150. TUMA DIRECT na Pesalink. Ambia HR atume salo Direct from bank, 24/7, NO CUT-OFF. Download receipt here: https://r.pesalink.co.ke/r1=76w7ExVt',
    ),
    (
      sender: 'MPESA',
      body:
          'UGHDL01LT0 Confirmed.on 17/7/26 at 4:37 PMWithdraw Ksh500.00 from 2059881 - JAMBU COMTECH Baraka shopKasarani New M-PESA balance is Ksh2,320.38. Transaction cost, Ksh29.00. Amount you can transact within the day is 499,010.00. Get a Lipa Na M-PESA Till online: https://m-pesaforbusiness.co.ke/',
    ),
    (
      sender: 'MPESA',
      body:
          'Failed. Insufficient funds in your M-PESA account as well as Fuliza M-PESA to send KSH50.00. Your M-PESA balance KSH0.00. Available Fuliza M-PESA limit KSH33.56.',
    ),
    (
      sender: 'MPESA',
      body:
          'UB6DL632FM Confirmed. Your account balance was: M-PESA Account : Ksh0.00 Business Account : Ksh0.00 on 6/2/26 at 5:19 PM. Transaction cost, Ksh0.00. Start Investing today with Ziidi MMF & earn daily. Dial *334#',
    ),
    (
      sender: 'MPESA',
      body:
          'Dear BELINZE, your Fuliza M-PESA limit is Ksh 900.00. You have an outstanding amount of Ksh 799.89 due on 25/10/25. Transaction Cost Ksh 0.',
    ),
    (
      sender: 'MPESA',
      body:
          'UGVDL1O5UV Confirmed. Fuliza M-PESA amount is Ksh 20.00. Access Fee charged Ksh 0.20. Total Fuliza M-PESA outstanding amount is Ksh102.06 due on 30/08/26. To check daily charges, Dial *334#OK Select Query Charges',
    ),
    (
      sender: 'MPESA',
      body:
          'TGI4HPX4PK Confirmed. Fuliza M-PESA amount is Ksh 100.00. Interest charged Ksh 1.00. Total Fuliza M-PESA outstanding amount is Ksh 724.62 due on 14/08/25. To check daily charges, Dial *334#OK Select Fuliza M-PESA to Query Charges.',
    ),
    (
      sender: 'MPESA',
      body:
          'Confirmed. Ksh 250.00 from your M-PESA has been used to partially pay your outstanding Fuliza M-PESA. Your available Fuliza M-PESA limit is Ksh 263.56. Your M-PESA balance is 0.00.',
    ),
    (
      sender: 'MPESA',
      body:
          '2026-01-03: Fuliza M-PESA repayment Kshs 673.33. 2026-01-03: Send Money with Fuliza M-PESA amount Ksh 100.00, Access Fee Kshs 1.00.',
    ),
  ];

  for (final s in samples) {
    final isBank = GenericBankParser.looksLikeBankSms(s.body, sender: s.sender);
    final mp = parser.parseSingleDetailed(s.body, sender: s.sender);
    print('sender=${s.sender} isBank=$isBank');
    if (mp == null) {
      print('  → null (rejected)');
    } else {
      print(
        '  → ${mp.transactionType.name} route=${mp.route.name} conf=${mp.confidence.name} amount=${mp.amountKes} title="${mp.title}" reason=${mp.reason}',
      );
    }
  }
}
