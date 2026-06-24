import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expense_dialogs.dart';
import 'package:beltech/features/expenses/presentation/widgets/sms_import_dialogs.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/providers/global_search_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> handleExpenseSmsImport(
  BuildContext context,
  WidgetRef ref,
) async {
  final method = await showSmsImportMethodDialog(context);
  if (method == null) {
    return;
  }
  if (method == SmsImportMethod.deviceInbox) {
    if (!context.mounted) {
      return;
    }
    final window = await showSmsWindowDialog(context);
    if (window == null) {
      return;
    }
    final count = await ref
        .read(expenseWriteControllerProvider.notifier)
        .importFromDevice(window: window);
    if (context.mounted) {
      final label = count == 0
          ? 'No MPESA messages found in ${importWindowLabel(window)}'
          : 'Imported $count MPESA transactions from device';
      AppFeedback.info(context, label, ref: ref);
    }
    return;
  }
  if (!context.mounted) {
    return;
  }
  final input = await showSmsImportDialog(context);
  if (input == null || input.payload.trim().isEmpty) {
    return;
  }
  final count =
      await ref.read(expenseWriteControllerProvider.notifier).importSmsPayload(
            input.payload,
            window: input.window,
          );
  if (context.mounted) {
    final label = count == 0
        ? 'No MPESA messages found in ${importWindowLabel(input.window)}'
        : 'Imported $count MPESA transactions';
    AppFeedback.info(context, label, ref: ref);
  }
}

Future<void> editExpenseEntry(
  BuildContext context,
  WidgetRef ref,
  ExpenseItem expense,
) async {
  final updated = await showEditExpenseDialog(context, expense: expense);
  if (updated == null) {
    return;
  }
  await ref.read(expenseWriteControllerProvider.notifier).updateExpense(
        transactionId: expense.id,
        title: updated.title,
        category: updated.category,
        amountKes: updated.amountKes,
        occurredAt: updated.occurredAt,
      );
  if (context.mounted && !ref.read(expenseWriteControllerProvider).hasError) {
    AppFeedback.success(context, 'Transaction updated', ref: ref);
  }
}

void consumeExpenseSearchTarget(
  BuildContext context,
  WidgetRef ref,
  ExpensesSnapshot snapshot,
) {
  final target = ref.read(globalSearchDeepLinkTargetProvider);
  if (target?.kind != GlobalSearchKind.expense) {
    return;
  }
  ref.read(globalSearchDeepLinkTargetProvider.notifier).state = null;
  final recordId = target?.recordId;
  if (recordId == null) {
    return;
  }
  final expense =
      snapshot.transactions.where((item) => item.id == recordId).firstOrNull;
  if (expense == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        AppFeedback.info(
          context,
          'This expense record no longer exists.',
          ref: ref,
        );
      }
    });
    return;
  }
  ref.read(expenseFilterProvider.notifier).state = ExpenseFilter.all;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!context.mounted) {
      return;
    }
    await editExpenseEntry(context, ref, expense);
  });
}

Future<void> replayExpenseImportQueue(
  BuildContext context,
  WidgetRef ref,
) async {
  final count = await ref
      .read(expenseWriteControllerProvider.notifier)
      .replayImportQueue();
  if (!context.mounted) {
    return;
  }
  final label = count == 0
      ? 'Replay finished. No new transactions were added.'
      : 'Replay imported $count transactions.';
  AppFeedback.info(context, label, ref: ref);
}
