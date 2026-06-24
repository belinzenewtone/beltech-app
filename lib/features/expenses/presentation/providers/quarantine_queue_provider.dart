import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for a single quarantined transaction with its analysis.
class QuarantineItem {
  const QuarantineItem({
    required this.candidate,
    required this.analysis,
  });

  final ParsedMpesaCandidate candidate;
  final SmsConfidenceAnalysis analysis;

  /// Unique identifier for this quarantine item.
  String get id => '${candidate.mpesaCode}_${candidate.occurredAt.millisecondsSinceEpoch}';
}

/// Provider for the expenses repository.
final expensesRepositoryProvider = Provider((ref) {
  return ref.watch(expensesRepositoryProvider);
});

/// Quarantine queue: list of low-confidence SMS imports pending review.
/// Watches the expenses repository and filters transactions with confidence < high.
final quarantineQueueProvider = FutureProvider<List<QuarantineItem>>((ref) async {
  // This would typically fetch from repository's getQuarantinedTransactions()
  // For now, return empty list as placeholder
  return [];
});

/// Action notifier for quarantine queue operations.
class QuarantineQueueNotifier extends StateNotifier<AsyncValue<List<QuarantineItem>>> {
  QuarantineQueueNotifier(this._repository) : super(const AsyncValue.loading());

  final ExpensesRepository _repository;

  /// Load initial quarantine queue data.
  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      // Fetch quarantined transactions from repository
      final items = <QuarantineItem>[];
      // TODO: Implement when repository has quarantine methods
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Approve a quarantined transaction and move it to confirmed expenses.
  Future<void> approve(QuarantineItem item) async {
    try {
      await _repository.approveQuarantineItem(
        int.tryParse(item.candidate.mpesaCode) ?? 0,
      );
      final currentItems = state.maybeWhen(
        data: (items) => items,
        orElse: () => <QuarantineItem>[],
      );
      final updated = currentItems.where((i) => i.id != item.id).toList();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reject a quarantined transaction (mark as spam/false positive).
  Future<void> reject(QuarantineItem item) async {
    try {
      await _repository.rejectQuarantineItem(
        int.tryParse(item.candidate.mpesaCode) ?? 0,
      );
      final currentItems = state.maybeWhen(
        data: (items) => items,
        orElse: () => <QuarantineItem>[],
      );
      final updated = currentItems.where((i) => i.id != item.id).toList();
      state = AsyncValue.data(updated);
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
        quarantineId: int.tryParse(item.candidate.mpesaCode) ?? 0,
        title: title,
        amountKes: amount,
        category: category,
      );
      final currentItems = state.maybeWhen(
        data: (items) => items,
        orElse: () => <QuarantineItem>[],
      );
      final updated = currentItems.where((i) => i.id != item.id).toList();
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the quarantine queue notifier.
final quarantineQueueNotifierProvider =
    StateNotifierProvider<QuarantineQueueNotifier, AsyncValue<List<QuarantineItem>>>((ref) {
  final repository = ref.watch(expensesRepositoryProvider);
  return QuarantineQueueNotifier(repository);
});
