import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final billsProvider = StreamProvider<List<BillItem>>((ref) {
  return ref.watch(billsRepositoryProvider).watchBills();
});

final monthlyCommitmentProvider = FutureProvider<double>((ref) {
  return ref.watch(billsRepositoryProvider).monthlyCommitmentTotal();
});

class BillsWriteController extends AutoDisposeAsyncNotifier<void> {
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
    });
  }

  Future<void> deleteBill(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(billsRepositoryProvider).deleteBill(id);
      ref.invalidate(billsProvider);
      ref.invalidate(monthlyCommitmentProvider);
    });
  }
}

final billsWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<BillsWriteController, void>(
      BillsWriteController.new,
    );
