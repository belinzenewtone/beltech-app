import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/data/services/sms_confidence_scorer.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpensesRepository extends Mock implements ExpensesRepository {}

void main() {
  late MockExpensesRepository repository;
  late MpesaParserService parser;
  late SmsConfidenceScorer scorer;
  late QuarantineQueueNotifier notifier;

  const rawMessage =
      'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.';

  setUp(() {
    repository = MockExpensesRepository();
    parser = const MpesaParserService();
    scorer = SmsConfidenceScorer();
    notifier = QuarantineQueueNotifier(repository, parser, scorer);
  });

  group('QuarantineQueueNotifier', () {
    test('load parses repository items and exposes them', () async {
      final createdAt = DateTime(2026, 3, 7, 18, 24);
      when(() => repository.fetchQuarantineItems(limit: 50))
          .thenAnswer((_) async => [
                ExpenseQuarantineItem(
                  id: 42,
                  reason: 'Low confidence',
                  confidence: 0.35,
                  rawMessage: rawMessage,
                  createdAt: createdAt,
                ),
              ]);

      await notifier.load();

      final state = notifier.state;
      expect(state.hasValue, isTrue);
      final items = state.value!;
      expect(items, hasLength(1));
      expect(items.first.quarantineId, 42);
      expect(items.first.candidate.title, 'Sky Cafe');
      expect(items.first.candidate.amountKes, 1250);
      expect(items.first.reason, 'Low confidence');
    });

    test('load returns empty list when repository has no items', () async {
      when(() => repository.fetchQuarantineItems(limit: 50))
          .thenAnswer((_) async => []);

      await notifier.load();

      expect(notifier.state.value, isEmpty);
    });

    test('approve uses quarantine id and removes item from state', () async {
      final createdAt = DateTime(2026, 3, 7, 18, 24);
      when(() => repository.fetchQuarantineItems(limit: 50))
          .thenAnswer((_) async => [
                ExpenseQuarantineItem(
                  id: 42,
                  reason: 'Low confidence',
                  confidence: 0.35,
                  rawMessage: rawMessage,
                  createdAt: createdAt,
                ),
              ]);
      when(() => repository.approveQuarantineItem(42))
          .thenAnswer((_) async {});

      await notifier.load();
      final item = notifier.state.value!.first;
      await notifier.approve(item);

      verify(() => repository.approveQuarantineItem(42)).called(1);
      expect(notifier.state.value, isEmpty);
    });

    test('reject uses quarantine id and removes item from state', () async {
      final createdAt = DateTime(2026, 3, 7, 18, 24);
      when(() => repository.fetchQuarantineItems(limit: 50))
          .thenAnswer((_) async => [
                ExpenseQuarantineItem(
                  id: 7,
                  reason: 'Missing amount',
                  confidence: 0.2,
                  rawMessage: rawMessage,
                  createdAt: createdAt,
                ),
              ]);
      when(() => repository.rejectQuarantineItem(7)).thenAnswer((_) async {});

      await notifier.load();
      final item = notifier.state.value!.first;
      await notifier.reject(item);

      verify(() => repository.rejectQuarantineItem(7)).called(1);
      expect(notifier.state.value, isEmpty);
    });

    test('approveWithEdits uses quarantine id and removes item from state',
        () async {
      final createdAt = DateTime(2026, 3, 7, 18, 24);
      when(() => repository.fetchQuarantineItems(limit: 50))
          .thenAnswer((_) async => [
                ExpenseQuarantineItem(
                  id: 99,
                  reason: 'Missing amount',
                  confidence: 0.2,
                  rawMessage: rawMessage,
                  createdAt: createdAt,
                ),
              ]);
      when(
        () => repository.updateAndApproveQuarantineItem(
          quarantineId: 99,
          title: 'Sky Cafe Dinner',
          amountKes: 1500,
          category: 'Food & Dining',
        ),
      ).thenAnswer((_) async {});

      await notifier.load();
      final item = notifier.state.value!.first;
      await notifier.approveWithEdits(
        item,
        'Sky Cafe Dinner',
        1500,
        'Food & Dining',
      );

      verify(
        () => repository.updateAndApproveQuarantineItem(
          quarantineId: 99,
          title: 'Sky Cafe Dinner',
          amountKes: 1500,
          category: 'Food & Dining',
        ),
      ).called(1);
      expect(notifier.state.value, isEmpty);
    });

    test('load surfaces errors as AsyncError', () async {
      when(() => repository.fetchQuarantineItems(limit: 50))
          .thenThrow(Exception('db down'));

      await notifier.load();

      expect(notifier.state.hasError, isTrue);
    });
  });
}
