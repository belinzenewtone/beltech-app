import 'dart:async';

import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/expenses/domain/services/balance_reconciliation_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_detection.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/entities/merchant_registry_entry.dart';
import 'package:beltech/features/expenses/domain/usecases/import_expenses_use_case.dart';
import 'package:beltech/features/expenses/domain/usecases/manage_expense_import_review_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum ExpenseFilter { all, today, week, month }

final expenseFilterProvider = StateProvider<ExpenseFilter>(
  (_) => ExpenseFilter.month,
);

/// Tracks whether the import-health banner has been dismissed this session.
/// Resets to false on app restart (in-memory only).
final importHealthBannerDismissedProvider = StateProvider<bool>((_) => false);

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

/// Computes the current outstanding Fuliza balance.
///
/// Prefers the authoritative value last stated in an SMS charge notice /
/// limit summary ("Total Fuliza M-PESA outstanding amount is Ksh X"), which is
/// far more accurate than summing draw/repayment events (those drift when the
/// wallet is topped up via other channels). Falls back to the event-sum when
/// no authoritative value has been seen.
final fulizaOutstandingBalanceProvider = FutureProvider<double>((ref) async {
  ref.watch(expensesSnapshotProvider);
  final authoritative = await ref
      .watch(localNotificationServiceProvider)
      .getFulizaOutstanding();
  if (authoritative > 0) {
    return authoritative;
  }
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

class ExpenseWriteController extends AsyncNotifier<void> {
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

  void _reportProgress(int done, int total) {
    ref.read(importProgressProvider.notifier).state =
        ImportProgress(done: done, total: total);
  }

  void _clearProgress() {
    ref.read(importProgressProvider.notifier).state = null;
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
    _reportProgress(0, lines.length);
    final result = await AsyncValue.guard(
      () => ref
          .read(importExpensesUseCaseProvider)
          .importRawMessages(lines, from: from, onProgress: _reportProgress),
    );
    _clearProgress();
    if (result.hasError) {
      state = AsyncError(
        result.error!,
        result.stackTrace ?? StackTrace.current,
      );
      throw result.error!;
    }
    state = const AsyncData(null);
    _invalidateImportReviewCaches();
    return result.value ?? 0;
  }

  Future<int> importFromDevice({
    required ExpenseImportWindow window,
    ImportSourceFilter filter = ImportSourceFilter.both,
  }) async {
    state = const AsyncLoading();
    // Show the progress banner immediately — the device scan phase can take
    // 10–30 s on a large inbox before the first onProgress callback fires.
    _reportProgress(0, 0);
    final result = await AsyncValue.guard(
      () => ref.read(importExpensesUseCaseProvider).importFromDevice(
            from: fromWindow(window),
            filter: filter,
            onProgress: _reportProgress,
          ),
    );
    _clearProgress();
    if (result.hasError) {
      state = AsyncError(
        result.error!,
        result.stackTrace ?? StackTrace.current,
      );
      // Partial data may have been written before the error; refresh caches
      // so any successfully imported transactions are visible immediately.
      _invalidateImportReviewCaches();
      throw result.error!;
    }
    state = const AsyncData(null);
    _invalidateImportReviewCaches();
    return result.value ?? 0;
  }

  /// Detect-only scan: counts financial messages per institution for the
  /// window/filter so the UI can preview before the user commits to importing.
  Future<ExpenseImportDetection> detectFromDevice({
    required ExpenseImportWindow window,
    ImportSourceFilter filter = ImportSourceFilter.both,
  }) async {
    return ref.read(importExpensesUseCaseProvider).detectFromDevice(
          from: fromWindow(window),
          filter: filter,
        );
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
    return result.value ?? 0;
  }

  void _invalidateImportReviewCaches() {
    ref.invalidate(expenseImportMetricsProvider);
    ref.invalidate(expenseReviewQueueProvider);
    ref.invalidate(expenseQuarantineQueueProvider);
    ref.invalidate(expensePaybillProfilesProvider);
    ref.invalidate(expenseFulizaLifecycleProvider);
    // Imported SMS may carry an updated Fuliza available-limit value.
    ref.invalidate(fulizaLimitProvider);
    // StateNotifierProviders don't re-fetch on invalidate() — call load()
    // explicitly so the review and quarantine screens reflect new data.
    ref.read(reviewQueueNotifierProvider.notifier).load();
    ref.read(quarantineQueueNotifierProvider.notifier).load();
  }
}

DateTime fromWindow(ExpenseImportWindow window) {
  final now = DateTime.now();
  return switch (window) {
    ExpenseImportWindow.last24Hours => now.subtract(const Duration(hours: 24)),
    ExpenseImportWindow.lastMonth => now.subtract(const Duration(days: 30)),
    ExpenseImportWindow.last3Months => now.subtract(const Duration(days: 90)),
    ExpenseImportWindow.last6Months => now.subtract(const Duration(days: 180)),
  };
}

/// Live import progress for the UI (null when no import is running).
final importProgressProvider = StateProvider<ImportProgress?>((ref) => null);

final expenseWriteControllerProvider =
    AsyncNotifierProvider<ExpenseWriteController, void>(
      ExpenseWriteController.new,
    );
