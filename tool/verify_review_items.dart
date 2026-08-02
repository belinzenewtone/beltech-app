// Verify the 8 review-queue items against the CURRENT parser.
// Run: dart run tool/verify_review_items.dart

import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';

void main() {
  const parser = MpesaParserService();

  final items = <({String sender, String body})>[
    (
      sender: 'IANDMBANK',
      body:
          'Transfer to Own Account of KES 1,000.00 to A/c 01705080913050 on 01/08/2026 11:29 processed successfully. Transaction Ref ID: 410425977499.',
    ),
    (
      sender: 'LOOP',
      body:
          'BELINZE, Online transaction of KES.182.77 has been approved on your card ending **0553 at COMMANDCODE.AI. Forex Adjustment, KES.6.40 on 01/08/2026 10:01:04. If it\'s not yours, please call Loop 0730 714444/0709 714444 urgently.',
    ),
    (
      sender: 'PESALINK',
      body:
          'KES 2,500 received from BELINZE OJING into A/C ****6150. TUMA DIRECT na Pesalink. Ambia HR atume salo Direct from bank, 24/7, NO CUT-OFF. Download receipt here: https://r.pesalink.co.ke/r1=76w7ExVt',
    ),
    (
      sender: 'LOOP',
      body:
          'Dear BELINZE, you have received KES.21,349.50 into your account. LOOP Ref NHEUGFS8BEBN. 28/07/2026 17:12:46.',
    ),
    (
      sender: 'LOOP',
      body:
          'Dear BELINZE! You have successfully transfered KES.207.00 from 44******4117 to wallet.',
    ),
    (
      sender: 'IANDMBANK',
      body:
          'Dear Customer,You have received KES 1000 via PesaLink into Acc 01705080916150 Tran Ref 0138005720260801084612nlEj9xNm. For enquiry,call 020 3221000. IM Bank.',
    ),
  ];

  for (final item in items) {
    final r = parser.parseSingleDetailed(item.body, sender: item.sender);
    if (r == null) {
      print('[${item.sender}] → null (ignored)');
    } else {
      print(
        '[${item.sender}] → ${r.transactionType.name} route=${r.route.name} conf=${r.confidence.name} amount=${r.amountKes} "${r.title}"',
      );
    }
  }
}
