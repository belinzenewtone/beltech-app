import 'dart:async';

import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final billsProvider = StreamProvider<List<BillItem>>((ref) {
  return ref.watch(billsRepositoryProvider).watchBills();
});

final monthlyCommitmentProvider = FutureProvider<double>((ref) {
  return ref.watch(billsRepositoryProvider).monthlyCommitmentTotal();
});

class BillsWriteController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    BillUrgency urgency = BillUrgency.medium,
    String? recurrence,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(billsRepositoryProvider)
          .upsertBill(
            name: name,
            amount: amount,
            dueDate: dueDate,
            urgency: urgency,
            recurrence: recurrence,
          );
      ref.invalidate(billsProvider);
      ref.invalidate(monthlyCommitmentProvider);
      await _syncBillReminders();
    });
  }

  Future<void> updateBill({
    required int id,
    String? name,
    double? amount,
    DateTime? dueDate,
    BillUrgency? urgency,
    String? recurrence,
    bool? paid,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(billsRepositoryProvider)
          .updateBill(
            id: id,
            name: name,
            amount: amount,
            dueDate: dueDate,
            urgency: urgency,
            recurrence: recurrence,
            paid: paid,
          );
      ref.invalidate(billsProvider);
      ref.invalidate(monthlyCommitmentProvider);
      await _syncBillReminders();
    });
  }

  Future<void> deleteBill(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(billsRepositoryProvider).deleteBill(id);
      await ref.read(localNotificationServiceProvider).cancelBillReminder(id);
      ref.invalidate(billsProvider);
      ref.invalidate(monthlyCommitmentProvider);
    });
  }

  /// Reconciles OS-scheduled reminders with the current bills: unpaid bills get
  /// (re)scheduled at their due date, paid bills have their reminders cancelled.
  /// Idempotent — safe to call after any mutation.
  Future<void> _syncBillReminders() async {
    final notifications = ref.read(localNotificationServiceProvider);
    final bills = await ref.read(billsRepositoryProvider).loadBills();
    for (final bill in bills) {
      if (bill.paid) {
        await notifications.cancelBillReminder(bill.id);
      } else {
        await notifications.scheduleBillReminder(
          billId: bill.id,
          billName: bill.name,
          amount: bill.amount,
          dueDate: bill.dueDate,
        );
      }
    }
  }
}

final billsWriteControllerProvider =
    AsyncNotifierProvider<BillsWriteController, void>(
      BillsWriteController.new,
    );
