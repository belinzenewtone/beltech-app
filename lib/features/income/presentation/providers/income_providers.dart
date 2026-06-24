import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/income/domain/entities/income_overview.dart';
import 'package:beltech/features/income/domain/usecases/build_income_overview_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final incomesProvider = StreamProvider<List<IncomeItem>>(
  (ref) => ref.watch(incomeRepositoryProvider).watchIncomes(),
);

final incomeExpenseSnapshotProvider = StreamProvider<ExpensesSnapshot>(
  (ref) => ref.watch(expensesRepositoryProvider).watchSnapshot(),
);

final buildIncomeOverviewUseCaseProvider = Provider<BuildIncomeOverviewUseCase>(
  (_) => const BuildIncomeOverviewUseCase(),
);

final incomeOverviewProvider = Provider<AsyncValue<IncomeOverview>>((ref) {
  final incomesState = ref.watch(incomesProvider);
  final expensesState = ref.watch(incomeExpenseSnapshotProvider);
  if (incomesState.hasError) {
    return AsyncError(
      incomesState.error!,
      incomesState.stackTrace ?? StackTrace.current,
    );
  }
  if (expensesState.hasError) {
    return AsyncError(
      expensesState.error!,
      expensesState.stackTrace ?? StackTrace.current,
    );
  }
  if (incomesState.isLoading || expensesState.isLoading) {
    return const AsyncLoading();
  }

  return AsyncData(
    ref.read(buildIncomeOverviewUseCaseProvider)(
          incomes: incomesState.valueOrNull ?? const [],
          expenseTransactions:
              expensesState.valueOrNull?.transactions ?? const <ExpenseItem>[],
        ),
  );
});

class IncomeWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addIncome({
    required String title,
    required double amountKes,
    DateTime? receivedAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(incomeRepositoryProvider).addIncome(
            title: title,
            amountKes: amountKes,
            receivedAt: receivedAt,
          );
    });
  }

  Future<void> updateIncome({
    required int incomeId,
    required String title,
    required double amountKes,
    required DateTime receivedAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(incomeRepositoryProvider).updateIncome(
            incomeId: incomeId,
            title: title,
            amountKes: amountKes,
            receivedAt: receivedAt,
          );
    });
  }

  Future<void> deleteIncome(int incomeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(incomeRepositoryProvider).deleteIncome(incomeId);
    });
  }
}

final incomeWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<IncomeWriteController, void>(
  IncomeWriteController.new,
);
