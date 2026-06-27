import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/data/services/sms_confidence_scorer.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for a single quarantined transaction with its analysis.
class QuarantineItem {
  const QuarantineItem({
    required this.quarantineId,
    required this.candidate,
    required this.analysis,
    required this.reason,
  });

  /// The database row id of the quarantine record.
  final int quarantineId;

  /// Parsed M-PESA transaction candidate produced from the raw message.
  final ParsedMpesaCandidate candidate;

  /// Confidence analysis for the parsed candidate.
  final SmsConfidenceAnalysis analysis;

  /// Why the message was quarantined (e.g. "Missing amount").
  final String reason;

  /// Unique identifier for this quarantine item.
  String get id => 'quarantine_$quarantineId';
}

/// Provider for the M-PESA parser service.
final mpesaParserServiceProvider = Provider<MpesaParserService>(
  (_) => const MpesaParserService(),
);

/// Provider for the SMS confidence scorer.
final smsConfidenceScorerProvider = Provider<SmsConfidenceScorer>(
  (_) => SmsConfidenceScorer(),
);

/// Action notifier for quarantine queue operations.
class QuarantineQueueNotifier
    extends StateNotifier<AsyncValue<List<QuarantineItem>>> {
  QuarantineQueueNotifier(
    this._repository,
    this._parser,
    this._scorer,
  ) : super(const AsyncValue.loading());

  final ExpensesRepository _repository;
  final MpesaParserService _parser;
  final SmsConfidenceScorer _scorer;

  /// Load initial quarantine queue data.
  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final rawItems = await _repository.fetchQuarantineItems(limit: 50);
      final parsedItems = <QuarantineItem>[];

      for (final raw in rawItems) {
        final candidate = _parser.parseSingleDetailed(
              raw.rawMessage,
              fallbackOccurredAt: raw.createdAt,
            ) ??
            _syntheticCandidate(raw);

        final analysis = _scorer.scoreTransaction(candidate: candidate);
        parsedItems.add(
          QuarantineItem(
            quarantineId: raw.id,
            candidate: candidate,
            analysis: analysis,
            reason: raw.reason,
          ),
        );
      }

      state = AsyncValue.data(parsedItems);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  ParsedMpesaCandidate _syntheticCandidate(ExpenseQuarantineItem raw) {
    const title = 'Unclassified MPESA Message';
    return ParsedMpesaCandidate(
      mpesaCode: 'UNKNOWN',
      title: title,
      category: 'Other',
      amountKes: 0,
      occurredAt: raw.createdAt,
      rawMessage: raw.rawMessage,
      transactionType: MpesaTransactionType.unknown,
      confidence: MpesaConfidence.low,
      route: MpesaParseRoute.quarantine,
      sourceHash: _parser.sourceHash(raw.rawMessage),
      semanticHash: _parser.semanticHash(
        type: MpesaTransactionType.unknown,
        amountKes: 0,
        occurredAt: raw.createdAt,
        title: title,
      ),
      reason: raw.reason,
    );
  }

  /// Approve a quarantined transaction and move it to confirmed expenses.
  Future<void> approve(QuarantineItem item) async {
    try {
      await _repository.approveQuarantineItem(item.quarantineId);
      _removeItem(item.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reject a quarantined transaction (mark as spam/false positive).
  Future<void> reject(QuarantineItem item) async {
    try {
      await _repository.rejectQuarantineItem(item.quarantineId);
      _removeItem(item.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Edit and approve a quarantined transaction.
  Future<void> approveWithEdits(
    QuarantineItem item,
    String title,
    double amount,
    String? category,
  ) async {
    try {
      await _repository.updateAndApproveQuarantineItem(
        quarantineId: item.quarantineId,
        title: title,
        amountKes: amount,
        category: category,
      );
      _removeItem(item.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _removeItem(String id) {
    final currentItems = state.maybeWhen(
      data: (items) => items,
      orElse: () => <QuarantineItem>[],
    );
    final updated = currentItems.where((i) => i.id != id).toList();
    state = AsyncValue.data(updated);
  }
}

/// Provider for the quarantine queue notifier.
final quarantineQueueNotifierProvider =
    StateNotifierProvider<
      QuarantineQueueNotifier,
      AsyncValue<List<QuarantineItem>>
    >((ref) {
      final repository = ref.watch(expensesRepositoryProvider);
      final parser = ref.watch(mpesaParserServiceProvider);
      final scorer = ref.watch(smsConfidenceScorerProvider);
      return QuarantineQueueNotifier(repository, parser, scorer);
    });
