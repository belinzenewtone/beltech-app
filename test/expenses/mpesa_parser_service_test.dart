import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MpesaParserService();

  // ── Normalizer ────────────────────────────────────────────────────────────

  group('normalizeParserText', () {
    test('trims leading and trailing whitespace', () {
      expect(normalizeParserText('  hello  '), 'hello');
    });

    test('collapses internal runs of spaces', () {
      expect(normalizeParserText('a  b   c'), 'a b c');
    });

    test('collapses newlines and tabs', () {
      expect(normalizeParserText('a\nb\tc'), 'a b c');
    });

    test('replaces non-breaking space with regular space', () {
      expect(normalizeParserText('a\u00A0b'), 'a b');
    });

    test('replaces zero-width chars', () {
      expect(normalizeParserText('a\u200Bb'), 'ab');
      expect(normalizeParserText('hello\u200Bworld'), 'helloworld');
    });

    test('normalizes curly single quotes', () {
      expect(normalizeParserText('\u2018text\u2019'), "'text'");
    });

    test('normalizes em dash and en dash', () {
      expect(normalizeParserText('a\u2013b'), 'a-b');
      expect(normalizeParserText('a\u2014b'), 'a-b');
    });

    test('handles empty string', () {
      expect(normalizeParserText(''), '');
    });
  });

  // ── looksLikeMpesaMessage ─────────────────────────────────────────────────

  group('looksLikeMpesaMessage', () {
    test('matches "mpesa" keyword', () {
      expect(looksLikeMpesaMessage('mpesa transaction done'), isTrue);
    });

    test('matches "m-pesa" keyword', () {
      expect(looksLikeMpesaMessage('M-Pesa transfer completed'), isTrue);
    });

    test('matches "confirmed" + "ksh" combination', () {
      expect(looksLikeMpesaMessage('Confirmed. Ksh100.00 sent.'), isTrue);
    });

    test('rejects unrelated SMS', () {
      expect(looksLikeMpesaMessage('Your OTP is 123456'), isFalse);
    });

    test('rejects empty string', () {
      expect(looksLikeMpesaMessage(''), isFalse);
    });

    test('case-insensitive match on MPESA', () {
      expect(looksLikeMpesaMessage('MPESA transaction'), isTrue);
    });
  });

  group('noise filters', () {
    test('ignores fuliza service notice before parsing', () {
      final r = parser.parseSingleDetailed(
        'Dear customer, Fuliza M-PESA limit update: your available balance is Ksh1,200.00. Dial *234# for details.',
      );
      expect(r, isNull);
    });

    test('ignores ambiguous success receipt stubs', () {
      final r = parser.parseSingleDetailed(
        'AB12CD34EF Confirmed. Transaction completed successfully on 8/3/26 at 10:00 AM.',
      );
      expect(r, isNull);
    });
  });

  // ── parseSingleDetailed — routing ─────────────────────────────────────────

  group('parseSingleDetailed routing', () {
    test('sent transaction → high confidence → directLedger', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.',
      );
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.high);
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('withdrawal → medium confidence → reviewQueue', () {
      final r = parser.parseSingleDetailed(
        'AB12CD34EF Confirmed. Ksh300.00 withdrawn at ATM on 8/3/26 at 10:00 AM.',
      );
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.medium);
      expect(r.route, MpesaParseRoute.reviewQueue);
    });

    test('unknown type → low confidence → quarantine', () {
      final r = parser.parseSingleDetailed(
        'ZZ11YY22XX Confirmed. Ksh50.00 transfer noted on 7/3/26 at 4:00 PM.',
      );
      expect(r, isNotNull);
      expect(r!.confidence, MpesaConfidence.low);
      expect(r.route, MpesaParseRoute.quarantine);
    });
  });

  // ── parseSingleDetailed — transaction types ───────────────────────────────

  group('parseSingleDetailed transaction types', () {
    test('sent to person', () {
      final r = parser.parseSingleDetailed(
        'AA00BB11CC Confirmed. Ksh500.00 sent to JOHN DOE on 1/1/26 at 9:00 AM.',
      );
      expect(r!.transactionType, MpesaTransactionType.sent);
    });

    test('received from person', () {
      final r = parser.parseSingleDetailed(
        'BB11CC22DD Confirmed. Ksh2,000.00 received from JANE DOE on 2/2/26 at 11:00 AM.',
      );
      expect(r!.transactionType, MpesaTransactionType.received);
    });

    test('paybill payment', () {
      final r = parser.parseSingleDetailed(
        'CC22DD33EE Confirmed. Ksh850.00 sent to KPLC PREPAID for account 34567 on 3/3/26 at 8:00 AM.',
      );
      expect(r!.transactionType, MpesaTransactionType.paybill);
    });

    test('buy goods (paid to)', () {
      final r = parser.parseSingleDetailed(
        'DD33EE44FF Confirmed. Ksh150.00 paid to JAVA HOUSE on 4/4/26 at 1:00 PM.',
      );
      expect(r!.transactionType, MpesaTransactionType.buyGoods);
    });

    test('cash withdrawal', () {
      final r = parser.parseSingleDetailed(
        'EE44FF55GG Confirmed. Ksh1,000.00 withdraw from ATM on 5/5/26 at 3:00 PM.',
      );
      expect(r!.transactionType, MpesaTransactionType.withdrawal);
    });

    test('airtime purchase', () {
      final r = parser.parseSingleDetailed(
        'FF55GG66HH Confirmed. Ksh50.00 airtime recharge on 6/6/26 at 7:00 AM.',
      );
      expect(r!.transactionType, MpesaTransactionType.airtime);
    });

    test('fuliza draw', () {
      final r = parser.parseSingleDetailed(
        'GG66HH77II Confirmed. Ksh500.00 Fuliza M-PESA amount credited on 7/7/26 at 10:00 AM.',
      );
      expect(r!.transactionType, MpesaTransactionType.fulizaDraw);
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('fuliza repayment', () {
      final r = parser.parseSingleDetailed(
        'HH77II88JJ Confirmed. Ksh200.00 paid from your Fuliza M-PESA on 7/7/26 at 2:30 PM.',
      );
      expect(r!.transactionType, MpesaTransactionType.fulizaRepayment);
      expect(r.route, MpesaParseRoute.directLedger);
    });

    test('reversal', () {
      final r = parser.parseSingleDetailed(
        'II88JJ99KK Confirmed. Ksh750.00 transaction has been reversed on 8/8/26 at 9:15 AM.',
      );
      expect(r!.transactionType, MpesaTransactionType.reversal);
    });

    test('deposit', () {
      final r = parser.parseSingleDetailed(
        'JJ99KK00LL Confirmed. Ksh3,000.00 deposit received on 9/9/26 at 4:00 PM.',
      );
      expect(r!.transactionType, MpesaTransactionType.deposit);
    });
  });

  // ── parseSingleDetailed — amount extraction ───────────────────────────────

  group('parseSingleDetailed amount extraction', () {
    test('integer amount without decimals', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh500 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r!.amountKes, 500.0);
    });

    test('amount with comma thousand separator', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh1,500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r!.amountKes, 1500.0);
    });

    test('large amount with multiple commas', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh10,000.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r!.amountKes, 10000.0);
    });

    test('amount with KES instead of Ksh', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. KES 250.00 sent to JANE on 2/2/26 at 10:00 AM.',
      );
      expect(r!.amountKes, 250.0);
    });

    test('amount with single decimal place', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh99.5 sent to SHOP on 3/3/26 at 11:00 AM.',
      );
      expect(r!.amountKes, 99.5);
    });

    test('zero amount routes to quarantine', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh0.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r, isNotNull);
      expect(r!.route, MpesaParseRoute.quarantine);
    });

    test('missing amount routes to quarantine', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. transaction completed on 1/1/26 at 9:00 AM.',
      );
      expect(r, isNotNull);
      expect(r!.route, MpesaParseRoute.quarantine);
    });

    test('small amount parsed correctly', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh10.00 airtime on 1/1/26 at 9:00 AM.',
      );
      expect(r!.amountKes, 10.0);
    });

    test('extracts post-transaction mpesa balance', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM. New M-PESA balance is Ksh3,210.55.',
      );
      expect(r, isNotNull);
      expect(r!.balanceAfterKes, 3210.55);
    });
  });

  // ── parseSingleDetailed — date/time parsing ───────────────────────────────

  group('parseSingleDetailed date/time parsing', () {
    test('4-digit year', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN on 1/3/2026 at 9:00 AM.',
      );
      expect(r!.occurredAt.year, 2026);
      expect(r.occurredAt.month, 3);
      expect(r.occurredAt.day, 1);
    });

    test('2-digit year → normalized to 2000+', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN on 15/6/26 at 3:00 PM.',
      );
      expect(r!.occurredAt.year, 2026);
      expect(r.occurredAt.month, 6);
      expect(r.occurredAt.day, 15);
    });

    test('12-hour AM time', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN on 1/1/26 at 9:30 AM.',
      );
      expect(r!.occurredAt.hour, 9);
      expect(r.occurredAt.minute, 30);
    });

    test('12-hour PM time', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN on 1/1/26 at 2:45 PM.',
      );
      expect(r!.occurredAt.hour, 14);
      expect(r.occurredAt.minute, 45);
    });

    test('noon (12:00 PM) parsed correctly', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN on 1/1/26 at 12:00 PM.',
      );
      expect(r!.occurredAt.hour, 12);
    });

    test('midnight (12:00 AM) parsed correctly', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN on 1/1/26 at 12:00 AM.',
      );
      expect(r!.occurredAt.hour, 0);
    });

    test('missing date falls back to DateTime.now() (year matches)', () {
      final before = DateTime.now();
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN sometime.',
      );
      expect(r!.occurredAt.year, greaterThanOrEqualTo(before.year));
    });

    test('uses provided fallback timestamp when date is missing', () {
      final fallback = DateTime(2025, 12, 11, 14, 5);
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN sometime.',
        fallbackOccurredAt: fallback,
      );
      expect(r, isNotNull);
      expect(r!.occurredAt, fallback);
    });

    test('supports 24-hour clock timestamps', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN on 1/1/26 at 18:24.',
      );
      expect(r, isNotNull);
      expect(r!.occurredAt.hour, 18);
      expect(r.occurredAt.minute, 24);
    });

    test('invalid calendar date falls back to provided timestamp', () {
      final fallback = DateTime(2026, 1, 9, 8, 45);
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN on 32/13/26 at 9:00 AM.',
        fallbackOccurredAt: fallback,
      );
      expect(r, isNotNull);
      expect(r!.occurredAt, fallback);
    });
  });

  // ── parseSingleDetailed — quarantine cases ────────────────────────────────

  group('parseSingleDetailed quarantine', () {
    test('missing MPESA code → quarantine', () {
      final r = parser.parseSingleDetailed(
        'Confirmed. Ksh100.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r, isNotNull);
      expect(r!.route, MpesaParseRoute.quarantine);
      expect(r.reason, contains('code'));
    });

    test('amount of 0 → quarantine', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh0 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r!.route, MpesaParseRoute.quarantine);
    });

    test('quarantine record has mpesaCode UNKNOWN', () {
      final r = parser.parseSingleDetailed(
        'Confirmed. Ksh100.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r!.mpesaCode, 'UNKNOWN');
    });

    test('quarantine record has amountKes of 0', () {
      final r = parser.parseSingleDetailed(
        'Confirmed. Ksh100.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r!.amountKes, 0);
    });

    test('non-mpesa text returns null', () {
      expect(parser.parseSingleDetailed('Your OTP is 123456'), isNull);
    });

    test('empty string returns null', () {
      expect(parser.parseSingleDetailed(''), isNull);
    });

    test('whitespace-only string returns null', () {
      expect(parser.parseSingleDetailed('   '), isNull);
    });
  });

  // ── parseSingleDetailed — counterparty extraction ─────────────────────────

  group('parseSingleDetailed counterparty extraction', () {
    test('extracts counterparty from sent transaction', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh500.00 sent to MARY JANE on 1/1/26 at 9:00 AM.',
      );
      expect(r!.counterparty, isNotNull);
      expect(r.counterparty, 'Mary Jane');
    });

    test('extracts counterparty from received transaction', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh1,000.00 received from TOM SMITH on 2/2/26 at 10:00 AM.',
      );
      expect(r!.counterparty, 'Tom Smith');
    });

    test('extracts merchant from buy goods transaction', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh200.00 paid to JAVA HOUSE on 3/3/26 at 1:00 PM.',
      );
      expect(r!.counterparty, 'Java House');
    });

    test('extracts paybill merchant name', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh850.00 sent to KPLC PREPAID for account 34567 on 3/3/26 at 8:00 AM.',
      );
      expect(r!.counterparty, 'Kplc Prepaid');
    });

    test('extracts paybill merchant when sms uses acc shorthand', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh850.00 sent to KPLC PREPAID for acc 34567 on 3/3/26 at 8:00 AM.',
      );
      expect(r, isNotNull);
      expect(r!.counterparty, 'Kplc Prepaid');
    });

    test('title case applied to single-word counterparty', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to SAFARICOM on 1/1/26 at 9:00 AM.',
      );
      expect(r!.counterparty, 'Safaricom');
    });

    test('strips trailing phone digits from counterparty name', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 sent to JOHN DOE 254712345678 on 1/1/26 at 9:00 AM.',
      );
      expect(r!.counterparty, 'John Doe');
    });

    test('no counterparty falls back to type label', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh300.00 withdraw at Agent on 1/1/26 at 9:00 AM.',
      );
      expect(r!.title, isNotEmpty);
      expect(r.transactionType, MpesaTransactionType.withdrawal);
    });
  });

  // ── parseSingleDetailed — title building ─────────────────────────────────

  group('parseSingleDetailed title building', () {
    test('sent with counterparty uses counterparty as title', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh500.00 sent to ALICE BOB on 1/1/26 at 9:00 AM.',
      );
      expect(r!.title, 'Alice Bob');
    });

    test('withdrawal fallback title', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh500.00 withdraw at agent on 1/1/26 at 9:00 AM.',
      );
      expect(r!.title, 'Cash Withdrawal');
    });

    test('airtime fallback title', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh50.00 airtime purchased on 1/1/26 at 9:00 AM.',
      );
      expect(r!.title, 'Airtime Topup');
    });

    test('reversal fallback title', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh100.00 has been reversed on 1/1/26 at 9:00 AM.',
      );
      expect(r!.title, 'MPESA Reversal');
    });

    test('strips "via Kopo Kopo" from merchant title', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh200.00 paid to HOTEL DELITOS via Kopo Kopo on 1/1/26 at 9:00 AM.',
      );
      expect(r, isNotNull);
      expect(r!.title, 'Hotel Delitos');
    });
  });

  // ── parseSingleDetailed — category assignment ─────────────────────────────

  group('parseSingleDetailed category assignment', () {
    test('received → Income', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh5,000.00 received from EMPLOYER on 1/1/26 at 9:00 AM.',
      );
      expect(r!.category, 'Income');
    });

    test('paybill → Bills', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh850.00 sent to KPLC for account 99887 on 1/1/26 at 8:00 AM.',
      );
      expect(r!.category, 'Bills');
    });

    test('buyGoods → Food', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh200.00 paid to JAVA HOUSE on 1/1/26 at 1:00 PM.',
      );
      expect(r!.category, 'Food');
    });

    test('withdrawal → Cash', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh1,000.00 withdraw at agent on 1/1/26 at 9:00 AM.',
      );
      expect(r!.category, 'Cash');
    });

    test('deposit → Cash', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh2,000.00 deposit received on 1/1/26 at 9:00 AM.',
      );
      expect(r!.category, 'Cash');
    });

    test('airtime → Airtime', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh50.00 airtime purchased on 1/1/26 at 9:00 AM.',
      );
      expect(r!.category, 'Airtime');
    });

    test('fulizaDraw → Loan', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh500.00 Fuliza M-PESA amount credited on 1/1/26 at 9:00 AM.',
      );
      expect(r!.category, 'Loan');
    });

    test('fulizaRepayment → Loan', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh200.00 paid from your Fuliza M-PESA on 1/1/26 at 9:00 AM.',
      );
      expect(r!.category, 'Loan');
    });

    test('reversal of sent payment is refined to Income', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh800.00 sent to CITY CAFE has been reversed on 1/1/26 at 9:00 AM.',
      );
      expect(r!.transactionType, MpesaTransactionType.reversal);
      expect(r.category, 'Income');
    });

    test('reversal of received payment stays non-income', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh800.00 received from JOHN DOE has been reversed on 1/1/26 at 9:00 AM.',
      );
      expect(r!.transactionType, MpesaTransactionType.reversal);
      expect(r.category, isNot('Income'));
    });
  });

  // ── parseSingleDetailed — paybill account ────────────────────────────────

  group('parseSingleDetailed paybill account', () {
    test('extracts paybill account number', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to KPLC PREPAID for account 998877 on 7/3/26 at 6:24 PM.',
      );
      expect(r!.paybillAccount, '998877');
    });

    test('extracts alphanumeric account reference', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh500.00 sent to SAFARICOM for account 072ABC99 on 1/1/26 at 9:00 AM.',
      );
      expect(r!.paybillAccount, isNotNull);
    });

    test('extracts account when message uses for acc shorthand', () {
      final r = parser.parseSingleDetailed(
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to KPLC PREPAID for acc 998877 on 7/3/26 at 6:24 PM.',
      );
      expect(r, isNotNull);
      expect(r!.paybillAccount, '998877');
      expect(r.transactionType, MpesaTransactionType.paybill);
    });

    test('null paybill account for non-paybill transaction', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r!.paybillAccount, isNull);
    });
  });

  // ── Hash determinism ──────────────────────────────────────────────────────

  group('hash determinism', () {
    const sms =
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.';

    test('sourceHash is deterministic for identical messages', () {
      final a = parser.parseSingleDetailed(sms);
      final b = parser.parseSingleDetailed(sms);
      expect(a!.sourceHash, b!.sourceHash);
    });

    test('semanticHash is deterministic for identical messages', () {
      final a = parser.parseSingleDetailed(sms);
      final b = parser.parseSingleDetailed(sms);
      expect(a!.semanticHash, b!.semanticHash);
    });

    test('sourceHash differs for different messages', () {
      const sms2 =
          'QW12AB34CD Confirmed. Ksh500.00 sent to JOHN on 7/3/26 at 6:24 PM.';
      final a = parser.parseSingleDetailed(sms);
      final b = parser.parseSingleDetailed(sms2);
      expect(a!.sourceHash, isNot(b!.sourceHash));
    });

    test('semanticHash differs for different amounts', () {
      const sms2 =
          'QW12AB34XY Confirmed. Ksh999.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.';
      final a = parser.parseSingleDetailed(sms);
      final b = parser.parseSingleDetailed(sms2);
      expect(a!.semanticHash, isNot(b!.semanticHash));
    });

    test('semanticHash differs for different dates', () {
      const sms2 =
          'QW12AB34XY Confirmed. Ksh1,250.00 sent to SKY CAFE on 8/3/26 at 6:24 PM.';
      final a = parser.parseSingleDetailed(sms);
      final b = parser.parseSingleDetailed(sms2);
      expect(a!.semanticHash, isNot(b!.semanticHash));
    });

    test('sourceHash is 64 hex chars (SHA-256)', () {
      final r = parser.parseSingleDetailed(sms);
      expect(r!.sourceHash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(r.sourceHash), isTrue);
    });

    test('semanticHash is 64 hex chars (SHA-256)', () {
      final r = parser.parseSingleDetailed(sms);
      expect(r!.semanticHash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(r.semanticHash), isTrue);
    });
  });

  // ── parseMany / parseManyDetailed ─────────────────────────────────────────

  group('parseMany', () {
    test('filters out quarantined results', () {
      final messages = [
        'QW12AB34CD Confirmed. Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
        'No mpesa code. Just noise.',
        'Confirmed. Ksh50.00 from unknown on 1/1/26 at 9:00 AM.',
      ];
      final results = parser.parseMany(messages);
      // Only messages that look like M-Pesa AND have high/medium confidence
      for (final r in results) {
        expect(r.amountKes, greaterThan(0));
      }
    });

    test(
      'returns all candidates including quarantine via parseManyDetailed',
      () {
        final messages = [
          'QW12AB34CD Confirmed. Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
          'Confirmed. missing code Ksh50.00 on 1/1/26 at 9:00 AM.',
        ];
        final results = parser.parseManyDetailed(messages);
        expect(results.length, greaterThanOrEqualTo(1));
      },
    );

    test('empty list returns empty list', () {
      expect(parser.parseMany([]), isEmpty);
      expect(parser.parseManyDetailed([]), isEmpty);
    });

    test('single valid message returns single result', () {
      final results = parser.parseMany([
        'AA11BB22CC Confirmed. Ksh200.00 sent to ALICE on 2/2/26 at 10:00 AM.',
      ]);
      expect(results.length, 1);
    });

    test('non-mpesa messages are filtered completely', () {
      final results = parser.parseMany([
        'Your OTP is 123456',
        'Package delivered',
        'Promotion: 50% off today',
      ]);
      expect(results, isEmpty);
    });
  });

  // ── parseBulkText ─────────────────────────────────────────────────────────

  group('parseBulkText', () {
    test('splits on blank lines and parses each chunk', () {
      const payload = '''
AA11BB22CC Confirmed. Ksh500.00 sent to ALICE on 1/1/26 at 9:00 AM.

BB22CC33DD Confirmed. Ksh800.00 received from BOB on 2/2/26 at 10:00 AM.
''';
      final results = parser.parseBulkText(payload);
      expect(results.length, 2);
    });

    test('handles extra blank lines gracefully', () {
      const payload = '''

AA11BB22CC Confirmed. Ksh500.00 sent to ALICE on 1/1/26 at 9:00 AM.



BB22CC33DD Confirmed. Ksh800.00 received from BOB on 2/2/26 at 10:00 AM.

''';
      final results = parser.parseBulkText(payload);
      expect(results.length, 2);
    });

    test('empty string returns empty list', () {
      expect(parser.parseBulkText(''), isEmpty);
    });
  });

  // ── parseSingle ───────────────────────────────────────────────────────────

  group('parseSingle', () {
    test('returns null for quarantine candidates', () {
      final r = parser.parseSingle(
        'Confirmed. missing code Ksh50.00 on 1/1/26 at 9:00 AM.',
      );
      expect(r, isNull);
    });

    test(
      'returns ParsedMpesaTransaction for valid high-confidence message',
      () {
        final r = parser.parseSingle(
          'AA11BB22CC Confirmed. Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
        );
        expect(r, isNotNull);
        expect(r!.amountKes, 500.0);
      },
    );

    test('returned object has correct rawMessage', () {
      const raw =
          'AA11BB22CC Confirmed. Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.';
      final r = parser.parseSingle(raw);
      expect(r!.rawMessage, normalizeParserText(raw));
    });
  });

  // ── confidenceScore ───────────────────────────────────────────────────────

  group('confidenceScore', () {
    test('high confidence → score >= 0.9', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r!.confidenceScore, greaterThanOrEqualTo(0.9));
    });

    test('medium confidence → score between 0.5 and 0.9', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh500.00 withdraw at agent on 1/1/26 at 9:00 AM.',
      );
      expect(r!.confidenceScore, inInclusiveRange(0.5, 0.9));
    });

    test('low confidence → score < 0.5', () {
      final r = parser.parseSingleDetailed(
        'ZZ11YY22XX Confirmed. Ksh50.00 transfer noted on 7/3/26 at 4:00 PM.',
      );
      expect(r!.confidenceScore, lessThan(0.5));
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────────

  group('edge cases', () {
    test('multiline SMS with embedded newlines is parsed', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed.\nKsh500.00 sent to\nJOHN DOE on 1/1/26 at 9:00 AM.',
      );
      expect(r, isNotNull);
      expect(r!.amountKes, 500.0);
    });

    test('message with non-breaking space is normalized', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC\u00A0Confirmed.\u00A0Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(r, isNotNull);
    });

    test('very short M-Pesa-like message returns null or quarantine', () {
      // Too short to have a code or amount
      final r = parser.parseSingle('MPESA ok');
      expect(r, isNull);
    });

    test('mpesa code must be exactly 10 alphanumeric chars', () {
      // 9-char code — should quarantine
      final r = parser.parseSingleDetailed(
        'AA11BB22C Confirmed. Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      // Either null (non-mpesa filter) or quarantine
      if (r != null) {
        expect(r.route, MpesaParseRoute.quarantine);
      }
    });

    test('KES and Ksh are treated equivalently', () {
      final kes = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. KES 500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      final ksh = parser.parseSingleDetailed(
        'BB22CC33DD Confirmed. Ksh500.00 sent to JOHN on 1/1/26 at 9:00 AM.',
      );
      expect(kes!.amountKes, ksh!.amountKes);
    });

    test('salary keyword in unknown transaction → Income category', () {
      final r = parser.parseSingleDetailed(
        'AA11BB22CC Confirmed. Ksh50,000.00 salary payment Ksh m-pesa on 1/1/26 at 9:00 AM.',
      );
      if (r != null && r.transactionType == MpesaTransactionType.unknown) {
        expect(r.category, 'Income');
      }
    });

    test('fuliza draw and repayment both parsed in single batch', () {
      final draw = parser.parseSingleDetailed(
        'AA12BB34CC Confirmed. Ksh500.00 Fuliza M-PESA amount credited on 8/3/26 at 10:00 AM.',
      );
      final repayment = parser.parseSingleDetailed(
        'DD56EE78FF Confirmed. Ksh200.00 paid from your Fuliza M-PESA on 8/3/26 at 2:30 PM.',
      );
      expect(draw!.transactionType, MpesaTransactionType.fulizaDraw);
      expect(repayment!.transactionType, MpesaTransactionType.fulizaRepayment);
    });
  });
}
