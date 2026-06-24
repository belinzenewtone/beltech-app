import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/budget/domain/entities/budget_target.dart';
import 'package:beltech/features/budget/domain/entities/budget_target_progress.dart';
import 'package:beltech/features/budget/domain/usecases/build_budget_target_progresses_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetMonthProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final budgetSnapshotProvider = StreamProvider<BudgetSnapshot>((ref) {
  final month = ref.watch(budgetMonthProvider);
  return ref.watch(budgetRepositoryProvider).watchMonthlySnapshot(month);
});

final budgetTargetsProvider = FutureProvider<List<BudgetTarget>>((ref) {
  return ref.watch(budgetRepositoryProvider).loadTargets();
});

final buildBudgetTargetProgressesUseCaseProvider =
    Provider<BuildBudgetTargetProgressesUseCase>(
  (_) => const BuildBudgetTargetProgressesUseCase(),
);

final budgetTargetProgressProvider =
    Provider<AsyncValue<List<BudgetTargetProgress>>>((ref) {
  final targetsState = ref.watch(budgetTargetsProvider);
  final snapshotState = ref.watch(budgetSnapshotProvider);
  if (targetsState.hasError) {
    return AsyncError(
      targetsState.error!,
      targetsState.stackTrace ?? StackTrace.current,
    );
  }
  if (snapshotState.hasError) {
    return AsyncError(
      snapshotState.error!,
      snapshotState.stackTrace ?? StackTrace.current,
    );
  }
  if (targetsState.isLoading || snapshotState.isLoading) {
    return const AsyncLoading();
  }

  return AsyncData(
    ref.read(buildBudgetTargetProgressesUseCaseProvider)(
      targets: targetsState.valueOrNull ?? const [],
      snapshot: snapshotState.valueOrNull ??
          BudgetSnapshot(month: DateTime.now(), items: const []),
    ),
  );
});

class BudgetWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveTarget({
    required String category,
    required double monthlyLimitKes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).upsertTarget(
            category: category,
            monthlyLimitKes: monthlyLimitKes,
          );
      ref.invalidate(budgetTargetsProvider);
    });
  }

  Future<void> deleteTarget(int targetId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).deleteTarget(targetId);
      ref.invalidate(budgetTargetsProvider);
    });
  }
}

final budgetWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<BudgetWriteController, void>(
  BudgetWriteController.new,
);
