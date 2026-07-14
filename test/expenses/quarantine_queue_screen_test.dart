import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/data/services/sms_confidence_scorer.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:beltech/features/expenses/presentation/screens/quarantine_queue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpensesRepository extends Mock implements ExpensesRepository {}

class _TestNotifier extends QuarantineQueueNotifier {
  _TestNotifier(super.repository, super.parser, super.scorer);

  @override
  Future<void> load() async {
    // no-op so tests can seed state directly
  }
}

void main() {
  testWidgets('shows empty state when queue is empty', (tester) async {
    final repository = MockExpensesRepository();
    final notifier = _TestNotifier(
      repository,
      const MpesaParserService(),
      SmsConfidenceScorer(),
    )..state = const AsyncValue.data([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quarantineQueueNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: QuarantineQueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing to review'), findsOneWidget);
  });

  testWidgets('shows quarantine item title and amount', (tester) async {
    final repository = MockExpensesRepository();
    final notifier = _TestNotifier(
      repository,
      const MpesaParserService(),
      SmsConfidenceScorer(),
    );

    final candidate = ParsedMpesaCandidate(
      mpesaCode: 'QW12AB34CD',
      title: 'Sky Cafe',
      category: 'Food & Dining',
      amountKes: 1250,
      occurredAt: DateTime(2026, 3, 7, 18, 24),
      rawMessage:
          'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM.',
      transactionType: MpesaTransactionType.sent,
      confidence: MpesaConfidence.low,
      route: MpesaParseRoute.quarantine,
      sourceHash: 'source',
      semanticHash: 'semantic',
    );

    notifier.state = AsyncValue.data([
      QuarantineItem(
        quarantineId: 42,
        candidate: candidate,
        analysis: SmsConfidenceScorer().scoreTransaction(
          candidate: candidate,
        ),
        reason: 'Low confidence',
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quarantineQueueNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: QuarantineQueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sky Cafe'), findsOneWidget);
    expect(find.text('Quarantined: Low confidence'), findsOneWidget);
  });
}
