// Phase P0 — accuracy harness / gap report.
//
// Runs the ported Kotlin golden corpus (231 real-world SMS) against the CURRENT
// Flutter parser and prints a per-field accuracy breakdown. This is a
// measurement tool, not yet a hard gate: it fails only if the corpus fails to
// load. Later (P6) we ratchet an accuracy floor once the gaps are closed.
//
// Run:  flutter test test/parser/golden_parser_test.dart

import 'package:beltech/features/expenses/data/services/generic_bank_parser.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/bank_fixtures.dart';
import 'fixtures/mpesa_fixtures.dart';
import 'fixtures/parser_fixture.dart';

/// Map the Dart parser's enum onto the Kotlin corpus string vocabulary.
String kindToString(MpesaTransactionType t) => switch (t) {
  MpesaTransactionType.sent => 'sent',
  MpesaTransactionType.received => 'received',
  MpesaTransactionType.paybill => 'paybill',
  MpesaTransactionType.buyGoods => 'buy_goods',
  MpesaTransactionType.withdrawal => 'withdraw',
  MpesaTransactionType.deposit => 'deposit',
  MpesaTransactionType.airtime => 'airtime',
  MpesaTransactionType.reversal => 'reversal',
  MpesaTransactionType.fulizaDraw => 'fuliza_draw',
  MpesaTransactionType.fulizaRepayment => 'fuliza_repayment',
  MpesaTransactionType.fulizaCharge => 'fuliza_charge',
  MpesaTransactionType.unknown => 'unknown',
};

String routeToString(MpesaParseRoute r) => switch (r) {
  MpesaParseRoute.directLedger => 'direct_ledger',
  MpesaParseRoute.reviewQueue => 'review_queue',
  MpesaParseRoute.quarantine => 'quarantine',
};

String confToString(MpesaConfidence c) => switch (c) {
  MpesaConfidence.high => 'high',
  MpesaConfidence.medium => 'medium',
  MpesaConfidence.low => 'low',
};

/// `fuliza_repayment` and `loan` are the same concept across the two corpora.
bool kindMatches(String expected, String actual) {
  if (expected == actual) return true;
  const loanish = {'fuliza_repayment', 'loan'};
  return loanish.contains(expected) && loanish.contains(actual);
}

class _Tally {
  int total = 0;
  int correct = 0;
  void add(bool ok) {
    total++;
    if (ok) correct++;
  }

  String pct() =>
      total == 0 ? '  n/a' : '${(100 * correct / total).toStringAsFixed(1)}%';
}

void main() {
  const parser = MpesaParserService();
  const bankParser = GenericBankParser();

  test('golden corpus loaded', () {
    expect(mpesaFixtures.length, greaterThan(150));
    expect(bankFixtures.length, greaterThan(40));
  });

  test('M-Pesa parser — gap report', () {
    final kind = _Tally();
    final amount = _Tally();
    final balance = _Tally();
    final route = _Tally();
    final conf = _Tally();
    final cparty = _Tally();
    final ignore = _Tally(); // shouldIgnore / expectedError handled
    final byKind = <String, _Tally>{};
    final misses = <String>[];

    for (final f in mpesaFixtures) {
      final r = parser.parseSingleDetailed(f.body);

      if (f.shouldIgnore || f.expectedError != null) {
        // Expect: rejected (null) or a balance-only Fuliza charge notice.
        final ok =
            r == null || r.transactionType == MpesaTransactionType.fulizaCharge;
        ignore.add(ok);
        if (!ok && misses.length < 30) {
          misses.add('IGNORE-MISS got=${kindToString(r!.transactionType)} :: '
              '${_snip(f.body)}');
        }
        continue;
      }

      if (r == null) {
        // Expected a transaction but got nothing — count as a miss on every set field.
        if (f.expectedKind != null) {
          kind.add(false);
          (byKind[f.expectedKind!] ??= _Tally()).add(false);
        }
        if (f.expectedAmount != null) amount.add(false);
        if (f.expectedBalance != null) balance.add(false);
        if (f.expectedRoute != null) route.add(false);
        if (f.expectedConfidence != null) conf.add(false);
        if (f.expectedCounterpartyContains != null) cparty.add(false);
        if (misses.length < 30) misses.add('NULL      exp=${f.expectedKind} :: ${_snip(f.body)}');
        continue;
      }

      if (f.expectedKind != null) {
        final ok = kindMatches(f.expectedKind!, kindToString(r.transactionType));
        kind.add(ok);
        (byKind[f.expectedKind!] ??= _Tally()).add(ok);
        if (!ok && misses.length < 30) {
          misses.add('KIND exp=${f.expectedKind} got=${kindToString(r.transactionType)} :: ${_snip(f.body)}');
        }
      }
      if (f.expectedAmount != null) {
        amount.add((r.amountKes - f.expectedAmount!).abs() < 0.01);
      }
      if (f.expectedBalance != null) {
        final b = r.balanceAfterKes;
        balance.add(b != null && (b - f.expectedBalance!).abs() < 0.01);
      }
      if (f.expectedRoute != null) {
        route.add(routeToString(r.route) == f.expectedRoute);
      }
      if (f.expectedConfidence != null) {
        conf.add(confToString(r.confidence) == f.expectedConfidence);
      }
      if (f.expectedCounterpartyContains != null) {
        final cp = (r.counterparty ?? r.title).toUpperCase();
        cparty.add(cp.contains(f.expectedCounterpartyContains!.toUpperCase()));
      }
    }

    // ignore: avoid_print
    print('''

================ M-PESA GAP REPORT (${mpesaFixtures.length} fixtures) ================
  kind            ${kind.pct()}   (${kind.correct}/${kind.total})
  amount          ${amount.pct()}   (${amount.correct}/${amount.total})
  balance         ${balance.pct()}   (${balance.correct}/${balance.total})
  route           ${route.pct()}   (${route.correct}/${route.total})
  confidence      ${conf.pct()}   (${conf.correct}/${conf.total})
  counterparty    ${cparty.pct()}   (${cparty.correct}/${cparty.total})
  ignore/reject   ${ignore.pct()}   (${ignore.correct}/${ignore.total})

  --- kind accuracy by type ---
${(byKind.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '  ${e.key.padRight(18)}${e.value.pct()}  (${e.value.correct}/${e.value.total})').join('\n')}

  --- first ${misses.length} misses ---
${misses.map((m) => '  $m').join('\n')}
==============================================================================
''');
  });

  test('Bank parser — gap report (note: sender not in corpus, body-only)', () {
    final detected = _Tally();
    final amount = _Tally();
    final direction = _Tally();
    final misses = <String>[];

    for (final f in bankFixtures) {
      final r = bankParser.tryParse(f.body);
      final isCredit = r != null &&
          !r.isReceivedReversal &&
          (r.transactionType == MpesaTransactionType.received ||
              r.category.toLowerCase() == 'income');

      detected.add(r != null);
      if (r == null) {
        if (misses.length < 20) misses.add('UNDETECTED :: ${_snip(f.body)}');
        continue;
      }
      if (f.expectedAmount != null) {
        amount.add((r.amountKes - f.expectedAmount!).abs() < 0.01);
      }
      if (f.expectedKind != null) {
        final actual = isCredit ? 'credit' : 'debit';
        direction.add(actual == f.expectedKind);
      }
    }

    // ignore: avoid_print
    print('''

================ BANK GAP REPORT (${bankFixtures.length} fixtures) ================
  detected        ${detected.pct()}   (${detected.correct}/${detected.total})
  amount          ${amount.pct()}   (${amount.correct}/${amount.total})
  direction       ${direction.pct()}   (${direction.correct}/${direction.total})

  --- first ${misses.length} undetected ---
${misses.map((m) => '  $m').join('\n')}
  NOTE: bank detection normally uses the SMS sender id, which the ported
  corpus dropped — real-world accuracy with sender will be higher.
==============================================================================
''');
  });
}

String _snip(String s) {
  final one = s.replaceAll('\n', ' ').replaceAll('\t', ' ');
  return one.length <= 68 ? one : '${one.substring(0, 68)}…';
}
