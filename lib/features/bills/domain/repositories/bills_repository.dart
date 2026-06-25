import 'package:beltech/features/bills/domain/entities/bill_item.dart';

abstract interface class BillsRepository {
  Stream<List<BillItem>> watchBills();
  Future<List<BillItem>> loadBills();
  Future<void> upsertBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    BillUrgency urgency,
    String? recurrence,
    bool paid,
  });
  Future<void> updateBill({
    required int id,
    String? name,
    double? amount,
    DateTime? dueDate,
    BillUrgency? urgency,
    String? recurrence,
    bool? paid,
  });
  Future<void> deleteBill(int id);
  Future<double> monthlyCommitmentTotal();
  Future<int> overdueCount();
}
