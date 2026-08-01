import 'package:beltech/features/expenses/data/services/generic_bank_parser.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = GenericBankParser();

  group('GenericBankParser.looksLikeBankSms', () {
    test('recognises sender from known bank name', () {
      expect(
        GenericBankParser.looksLikeBankSms('Ksh500 debited from your account', sender: 'KCB'),
        isTrue,
      );
    });

    test('recognises bank name in message body with amount', () {
      expect(
        GenericBankParser.looksLikeBankSms(
          'Your Equity Bank account was credited with Ksh1,200.00.',
        ),
        isTrue,
      );
    });

    test('ignores messages without KES/KSH', () {
      expect(
        GenericBankParser.looksLikeBankSms('KCB account statement ready.'),
        isFalse,
      );
    });

    test('ignores non-bank M-Pesa messages', () {
      expect(
        GenericBankParser.looksLikeBankSms(
          'QQ12345678 Confirmed. Ksh100.00 sent to John.',
        ),
        isFalse,
      );
    });
  });

  group('GenericBankParser.tryParse', () {
    test('parses KCB debit SMS', () {
      const msg = 'Your KCB account was debited Ksh2,500.00 on 15/7/26 at 10:30 AM. Balance: Ksh8,000.00.';
      final result = parser.tryParse(msg);
      expect(result, isNotNull);
      expect(result!.amountKes, closeTo(2500.0, 0.01));
      expect(result.transactionType, MpesaTransactionType.sent);
      expect(result.route, MpesaParseRoute.reviewQueue);
      expect(result.confidence, MpesaConfidence.medium);
      expect(result.title, contains('KCB'));
    });

    test('parses Equity credit SMS', () {
      const msg = 'Equity Bank: Ksh3,000.00 credited to your account on 1/8/26 at 2:15 PM.';
      final result = parser.tryParse(msg);
      expect(result, isNotNull);
      expect(result!.amountKes, closeTo(3000.0, 0.01));
      expect(result.transactionType, MpesaTransactionType.received);
      expect(result.category, 'Income');
    });

    test('parses sender-identified bank SMS', () {
      const msg = 'Your account was debited Ksh750.00 on 5/6/26 at 9:00 AM.';
      final result = parser.tryParse(msg, sender: 'NCBA');
      expect(result, isNotNull);
      expect(result!.counterparty, 'NCBA');
    });

    test('returns null when no amount found', () {
      const msg = 'Your KCB account transaction has been processed.';
      expect(parser.tryParse(msg), isNull);
    });

    test('returns null for non-bank SMS', () {
      const msg = 'QQ12345678 Confirmed. Ksh100.00 sent to Jane.';
      expect(parser.tryParse(msg), isNull);
    });

    test('sourceHash and semanticHash are non-empty strings', () {
      const msg = 'KCB: Ksh500.00 debited on 2/2/26 at 3:00 PM.';
      final result = parser.tryParse(msg, sender: 'KCB');
      expect(result, isNotNull);
      expect(result!.sourceHash, isNotEmpty);
      expect(result.semanticHash, isNotEmpty);
    });
  });
}
