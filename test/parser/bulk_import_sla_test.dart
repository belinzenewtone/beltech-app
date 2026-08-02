// Phase P6 — bulk import: pool-path parity + 50k throughput SLA.
//
// NOTE: run under the Dart VM (`flutter test`), so absolute timings are NOT the
// device SLA — they prove the pipeline handles the volume without hanging and
// that the isolate-pool path produces identical results to the proven path.

import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/core/isolate/parse_isolate_pool.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/mpesa_fixtures.dart';

// Real, distinct M-Pesa SMS from the golden corpus — they route across
// ledger / review / quarantine, so the outcome fingerprint is non-trivial.
List<String> _messages(int n) =>
    mpesaFixtures.take(n).map((f) => f.body).toList();

Future<int> _count(AppDriftStore store, String table) async {
  final rows = await store.executor.runSelect(
    'SELECT COUNT(*) AS c FROM $table',
    const [],
  );
  return (rows.first['c'] as num).toInt();
}

/// Fingerprint of where the import landed, across every destination.
Future<(int txns, int review, int quarantine)> _outcome(
  AppDriftStore store,
) async => (
  await _count(store, 'transactions'),
  await _count(store, 'sms_review_queue'),
  await _count(store, 'sms_quarantine'),
);

void main() {
  test('isolate-pool path imports identically to the proven path', () async {
    final messages = _messages(240); // > chunk size, triggers the pool

    final storeA = AppDriftStore();
    final repoA = ExpensesRepositoryImpl(storeA, const MpesaParserService())
      ..useIsolatePool = false;
    final importedA = await repoA.importSmsMessages(messages);
    final outcomeA = await _outcome(storeA);
    await storeA.dispose();

    final storeB = AppDriftStore();
    final repoB = ExpensesRepositoryImpl(storeB, const MpesaParserService())
      ..useIsolatePool = true; // <- pool path
    final importedB = await repoB.importSmsMessages(messages);
    final outcomeB = await _outcome(storeB);
    await storeB.dispose();

    expect(importedB, importedA, reason: 'same number auto-imported via the pool');
    expect(outcomeB, outcomeA, reason: 'identical routing across all destinations');
    final total = outcomeA.$1 + outcomeA.$2 + outcomeA.$3;
    expect(total, greaterThan(0), reason: 'the batch was actually processed');
  });

  test('import reports progress that advances to the total', () async {
    final store = AppDriftStore();
    final repo = ExpensesRepositoryImpl(store, const MpesaParserService());
    final messages = mpesaFixtures.take(250).map((f) => f.body).toList();

    final updates = <(int, int)>[];
    await repo.importSmsMessages(
      messages,
      onProgress: (done, total) => updates.add((done, total)),
    );
    await store.dispose();

    expect(updates, isNotEmpty, reason: 'progress must be reported');
    // done is non-decreasing and ends at the total.
    for (var i = 1; i < updates.length; i++) {
      expect(updates[i].$1, greaterThanOrEqualTo(updates[i - 1].$1));
    }
    expect(updates.last.$1, updates.last.$2, reason: 'ends at 100%');
  });

  test('50k SMS parse through the pool completes and stays aligned', () async {
    // Build 50k jobs by cycling the real golden corpus.
    final jobs = List.generate(
      50000,
      (i) => SmsParseJob(mpesaFixtures[i % mpesaFixtures.length].body),
    );

    final pool = ParseIsolatePool();
    final sw = Stopwatch()..start();
    final results = await pool.parseAll(jobs, chunkSize: 500);
    sw.stop();
    await pool.dispose();

    expect(results.length, 50000, reason: 'aligned 1:1 with 50k inputs');
    final parsed = results.where((r) => r != null).length;
    // ignore: avoid_print
    print('50k parsed in ${sw.elapsedMilliseconds}ms '
        '(${(50000 / sw.elapsedMilliseconds * 1000).round()}/s), '
        '$parsed non-null');
    expect(parsed, greaterThan(40000), reason: 'the corpus is mostly parseable');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
