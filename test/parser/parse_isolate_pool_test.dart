// Phase P2 — worker pool + bounded channel.

import 'package:beltech/core/isolate/bounded_channel.dart';
import 'package:beltech/core/isolate/parse_isolate_pool.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

String _received(String code, double amt) =>
    '$code Confirmed. You have received Ksh${amt.toStringAsFixed(2)} from '
    'PAYER $code 0712345678 on 16/3/26 at 11:20 AM. New M-PESA balance is Ksh9,000.00.';

void main() {
  group('ParseIsolatePool', () {
    late ParseIsolatePool pool;

    setUp(() => pool = ParseIsolatePool(workers: 3));
    tearDown(() => pool.dispose());

    test('parses a chunk, aligned 1:1 with input', () async {
      final jobs = [
        SmsParseJob(_received('AAA1111111', 100)),
        const SmsParseJob('non-financial chatter, ignore me'),
        SmsParseJob(_received('BBB2222222', 250)),
      ];
      final results = await pool.parseChunk(jobs);
      expect(results.length, 3);
      expect(results[0]?.amountKes, 100.0);
      expect(results[2]?.amountKes, 250.0);
      expect(results[1]?.amountKes, isNot(250.0));
    });

    test('parseAll preserves global order across many chunks/workers', () async {
      // 500 jobs, chunk 50 -> 10 chunks over 3 workers; order must survive
      // out-of-order completion.
      final jobs = List.generate(
        500,
        (i) => SmsParseJob(_received('C${i.toString().padLeft(9, '0')}', (i + 1).toDouble())),
      );
      final results = await pool.parseAll(jobs, chunkSize: 50);
      expect(results.length, 500);
      for (var i = 0; i < 500; i++) {
        expect(
          results[i]?.amountKes,
          (i + 1).toDouble(),
          reason: 'slot $i must hold job $i regardless of worker timing',
        );
      }
    });

    test('matches the synchronous reference exactly', () async {
      final jobs = List.generate(
        120,
        (i) => i.isEven
            ? SmsParseJob(_received('D${i.toString().padLeft(9, '0')}', (i + 1).toDouble()))
            : const SmsParseJob('lunch at 1?'),
      );
      final poolResults = await pool.parseAll(jobs, chunkSize: 32);
      final syncResults = MpesaParserService.parseJobsAlignedSync(jobs);
      expect(poolResults.length, syncResults.length);
      for (var i = 0; i < jobs.length; i++) {
        expect(poolResults[i]?.amountKes, syncResults[i]?.amountKes);
        expect(poolResults[i]?.transactionType, syncResults[i]?.transactionType);
      }
    });

    test('empty batch short-circuits', () async {
      expect(await pool.parseAll(const []), isEmpty);
      expect(await pool.parseChunk(const []), isEmpty);
    });

    // Audit regression: parseChunk after dispose must fail fast, not hang
    // forever (the disposed guard used to sit behind the _started early-return).
    test('parseChunk after dispose throws instead of hanging', () async {
      await pool.parseChunk([SmsParseJob(_received('EE0000000', 5))]);
      await pool.dispose();
      expect(
        () => pool.parseChunk([SmsParseJob(_received('FF0000000', 5))]),
        throwsStateError,
      );
    });
  });

  group('BoundedChannel', () {
    test('send blocks once capacity is reached, unblocks on receive', () async {
      final ch = BoundedChannel<int>(capacity: 2);
      await ch.send(1);
      await ch.send(2);

      var thirdSent = false;
      final pending = ch.send(3).then((_) => thirdSent = true);

      await Future<void>.delayed(Duration.zero);
      expect(thirdSent, isFalse, reason: 'buffer full → send must await');
      expect(ch.length, 2);

      expect(await ch.receive(), 1); // frees a slot
      await pending;
      expect(thirdSent, isTrue);
      expect(ch.length, 2); // 2 and 3 buffered
    });

    test('receive returns null after close & drain', () async {
      final ch = BoundedChannel<int>(capacity: 4);
      await ch.send(10);
      await ch.send(20);
      ch.close();
      expect(await ch.receive(), 10);
      expect(await ch.receive(), 20);
      expect(await ch.receive(), isNull);
    });

    test('producer/consumer stay bounded under a fast producer', () async {
      final ch = BoundedChannel<int>(capacity: 3);
      var maxObserved = 0;
      final producer = () async {
        for (var i = 0; i < 50; i++) {
          await ch.send(i);
          if (ch.length > maxObserved) maxObserved = ch.length;
        }
        ch.close();
      }();
      final received = <int>[];
      await for (final v in ch.stream()) {
        received.add(v);
        await Future<void>.delayed(Duration.zero); // slow consumer
      }
      await producer;
      expect(received.length, 50);
      expect(maxObserved, lessThanOrEqualTo(3), reason: 'never exceeds capacity');
    });
  });
}
