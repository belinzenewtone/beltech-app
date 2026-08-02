// Phase P1 — regression test for the dequeue index-alignment invariant.
//
// The import pipeline maps parsed results back to queue rows POSITIONALLY:
// `candidates[i]` is attached to `rows[i]`. That is only safe if the batch
// parser returns a list 1:1 aligned with its input. parseJobsInIsolateAligned
// guarantees `result[i]` is the parse of `jobs[i]` — so one message's
// transaction can never be attached to a different message's queue row, no
// matter which jobs parse, fail, or are reordered internally.

import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const received =
      'SIE8QWE123 Confirmed. You have received Ksh390.00 from JOHN DOE 0712345678 '
      'on 16/3/26 at 11:20 AM. New M-PESA balance is Ksh1,200.00.';
  const sent =
      'SIE8QWE124 Confirmed. Ksh777.00 sent to JANE DOE 0712345678 on 16/3/26 '
      'at 11:22 AM. New M-PESA balance is Ksh810.00.';
  const garbage = 'Hey, are we still meeting for lunch tomorrow? See you at 1pm.';

  test('result length always equals input length', () async {
    final results = await MpesaParserService.parseJobsInIsolateAligned(
      [received, garbage, sent].map(SmsParseJob.new).toList(),
    );
    expect(results.length, 3);
  });

  test('each slot holds its own job — no shifting past an unparseable row', () async {
    final jobs = [
      const SmsParseJob(received), // 0
      const SmsParseJob(garbage), //  1 (unparseable content)
      const SmsParseJob(sent), //     2
    ];

    final results = await MpesaParserService.parseJobsInIsolateAligned(jobs);

    // Slot 0 is the received txn.
    expect(results[0]?.transactionType, MpesaTransactionType.received);
    expect(results[0]?.amountKes, 390.0);

    // The critical assertion: the SENT txn lands in slot 2, NOT slot 1.
    // Under the old drop-and-index-map behaviour it would have shifted to 1.
    expect(results[2]?.transactionType, MpesaTransactionType.sent);
    expect(results[2]?.amountKes, 777.0);

    // Slot 1 (the garbage) must NOT carry the sent txn's amount.
    expect(results[1]?.amountKes, isNot(777.0));
  });

  test('leading unparseable job does not pull the next result into slot 0', () async {
    final jobs = [const SmsParseJob(garbage), const SmsParseJob(received)];
    final results = await MpesaParserService.parseJobsInIsolateAligned(jobs);

    expect(results.length, 2);
    expect(results[1]?.amountKes, 390.0); // received stays in slot 1
    expect(results[0]?.amountKes, isNot(390.0)); // slot 0 is the garbage's own result
  });

  test('empty batch returns empty', () async {
    final results = await MpesaParserService.parseJobsInIsolateAligned(const []);
    expect(results, isEmpty);
  });
}
