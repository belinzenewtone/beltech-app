import 'dart:async';

import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/expenses/domain/services/balance_reconciliation_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/entities/merchant_registry_entry.dart';
import 'package:beltech/features/expenses/domain/usecases/import_expenses_use_case.dart';
import 'package:beltech/features/expenses/domain/usecases/manage_expense_import_review_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExpenseFilter { all, today, week, month }

final expenseFilterProvider = StateProvider<ExpenseFilter>(
  (_) => ExpenseFilter.month,
);

final expensesSnapshotProvider = StreamProvider<ExpensesSnapshot>(
  (ref) => ref.watch(expensesRepositoryProvider).watchSnapshot(),
);

final importExpensesUseCaseProvider = Provider<ImportExpensesUseCase>(
  (ref) => ImportExpensesUseCase(ref.watch(expensesRepositoryProvider)),
);

final manageExpenseImportReviewUseCaseProvider =
    Provider<ManageExpenseImportReviewUseCase>(
      (ref) => ManageExpenseImportReviewUseCase(
        ref.watch(expensesRepositoryProvider),
      ),
    );

final expenseImportMetricsProvider = FutureProvider<ExpenseImportMetrics>((
  ref,
) {
  // Keep review/intelligence data fresh whenever the underlying store emits.
  ref.watch(expensesSnapshotProvider);
  return ref.watch(manageExpenseImportReviewUseCaseProvider).fetchMetrics();
});

final expenseReviewQueueProvider = FutureProvider<List<ExpenseReviewItem>>((
  ref,
) {
  ref.watch(expensesSnapshotProvider);
  return ref
      .watch(manageExpenseImportReviewUseCaseProvider)
      .fetchReviewQueue(limit: 20);
});

final expenseQuarantineQueueProvider =
    FutureProvider<List<ExpenseQuarantineItem>>((ref) {
      ref.watch(expensesSnapshotProvider);
      return ref
          .watch(manageExpenseImportReviewUseCaseProvider)
          .fetchQuarantine(limit: 20);
    });

final expensePaybillProfilesProvider = FutureProvider<List<PaybillProfile>>((
  ref,
) {
  ref.watch(expensesSnapshotProvider);
  return ref.watch(expensesRepositoryProvider).fetchPaybillProfiles(limit: 8);
});

final expenseFulizaLifecycleProvider =
    FutureProvider<List<FulizaLifecycleEvent>>((ref) {
      ref.watch(expensesSnapshotProvider);
      return ref
          .watch(expensesRepositoryProvider)
          .fetchFulizaLifecycle(limit: 8);
    });

final merchantRegistrySearchProvider = FutureProvider.family<
  List<MerchantRegistryEntry>,
  String
>((ref, query) async {
  ref.watch(expensesSnapshotProvider);
  if (query.trim().isEmpty) return const [];
  return ref.watch(expensesRepositoryProvider).searchMerchantRegistry(query);
});

final topMerchantsProvider = FutureProvider<List<MerchantRegistryEntry>>(
  (ref) async {
    ref.watch(expensesSnapshotProvider);
    return ref.watch(expensesRepositoryProvider).fetchTopMerchants(limit: 10);
  },
);

final balanceReconciliationProvider =
    FutureProvider<List<BalanceReconciliationResult>>(
  (ref) async {
    ref.watch(expensesSnapshotProvider);
    return BalanceReconciliationService(
      ref.watch(appDriftStoreProvider),
    ).reconcile(limit: 20);
  },
);

/// Computes the current outstanding Fuliza balance from all recorded events.
/// Positive = money owed; 0 = fully repaid or no activity.
final fulizaOutstandingBalanceProvider = FutureProvider<double>((ref) async {
  ref.watch(expensesSnapshotProvider);
  final events = await ref
      .watch(expensesRepositoryProvider)
      .fetchFulizaLifecycle(limit: 500);
  double balance = 0;
  for (final e in events) {
    if (e.kind == FulizaLifecycleKind.draw) {
      balance += e.amountKes;
    } else if (e.kind == FulizaLifecycleKind.repayment) {
      balance -= e.amountKes;
    }
  }
  return balance.clamp(0, double.infinity);
});

class ExpenseWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addQuickExpense() async {
    await addExpense(
      title: 'Manual Expense',
      category: 'Other',
      amountKes: 120,
    );
  }

  Future<void> addExpense({
    required String title,
    required String category,
    required double amountKes,
    DateTime? occurredAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(expensesRepositoryProvider)
          .addManualTransaction(
            title: title,
            category: category,
            amountKes: amountKes,
            occurredAt: occurredAt,
          );
    });
  }

  Future<void> updateExpense({
    required int transactionId,
    required String title,
    required String category,
    required double amountKes,
    required DateTime occurredAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(expensesRepositoryProvider)
          .updateTransaction(
            transactionId: transactionId,
            title: title,
            category: category,
            amountKes: amountKes,
            occurredAt: occurredAt,
          );
    });
  }

  Future<void> deleteExpense(int transactionId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(expensesRepositoryProvider)
          .deleteTransaction(transactionId);
    });
  }

  Future<int> importSmsPayload(
    String payload, {
    required ExpenseImportWindow window,
  }) async {
    final lines = payload
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return 0;
    }
    final from = fromWindow(window);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(importExpensesUseCaseProvider)
          .importRawMessages(lines, from: from),
    );
    if (result.hasError) {
      state = AsyncError(
        result.error!,
        result.stackTrace ?? StackTrace.current,
      );
      throw result.error!;
    }
    state = const AsyncData(null);
    _invalidateImportReviewCaches();
    return result.valueOrNull ?? 0;
  }

  Future<int> importFromDevice({required ExpenseImportWindow window}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(importExpensesUseCaseProvider)
          .importFromDevice(from: fromWindow(window)),
    );
    if (result.hasError) {
      state = AsyncError(
        result.error!,
        result.stackTrace ?? StackTrace.current,
      );
      throw result.error!;
    }
    state = const AsyncData(null);
    _invalidateImportReviewCaches();
    return result.valueOrNull ?? 0;
  }

  Future<void> approveReviewItem(int reviewId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(manageExpenseImportReviewUseCaseProvider)
          .resolveReviewItem(reviewId: reviewId, approve: true);
    });
    _invalidateImportReviewCaches();
  }

  Future<void> rejectReviewItem(int reviewId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(manageExpenseImportReviewUseCaseProvider)
          .resolveReviewItem(reviewId: reviewId, approve: false);
    });
    _invalidateImportReviewCaches();
  }

  Future<void> dismissQuarantineItem(int quarantineId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(manageExpenseImportReviewUseCaseProvider)
          .dismissQuarantineItem(quarantineId);
    });
    _invalidateImportReviewCaches();
  }

  Future<int> replayImportQueue() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(expensesRepositoryProvider).replayImportQueue(),
    );
    if (result.hasError) {
      state = AsyncError(
        result.error!,
        result.stackTrace ?? StackTrace.current,
      );
      throw result.error!;
    }
    state = const AsyncData(null);
    _invalidateImportReviewCaches();
    return result.valueOrNull ?? 0;
  }

  void _invalidateImportReviewCaches() {
    ref.invalidate(expenseImportMetricsProvider);
    ref.invalidate(expenseReviewQueueProvider);
    ref.invalidate(expenseQuarantineQueueProvider);
    ref.invalidate(expensePaybillProfilesProvider);
    ref.invalidate(expenseFulizaLifecycleProvider);
  }
}

DateTime fromWindow(ExpenseImportWindow window) {
  final now = DateTime.now();
  return switch (window) {
    ExpenseImportWindow.last24Hours => now.subtract(const Duration(hours: 24)),
    ExpenseImportWindow.last7Days => now.subtract(const Duration(days: 7)),
    ExpenseImportWindow.last30Days => now.subtract(const Duration(days: 30)),
    ExpenseImportWindow.last90Days => now.subtract(const Duration(days: 90)),
  };
}

final expenseWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExpenseWriteController, void>(
      ExpenseWriteController.new,
    );
