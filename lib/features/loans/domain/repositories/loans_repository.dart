import 'package:beltech/features/loans/domain/entities/loan_item.dart';

abstract interface class LoansRepository {
  Stream<List<LoanItem>> watchLoans();
  Future<List<LoanItem>> loadLoans();
  Future<void> addLoan({
    required String name,
    String? lender,
    required double totalAmount,
    required double outstandingAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus status,
  });
  Future<void> updateLoan({
    required int id,
    String? name,
    String? lender,
    double? totalAmount,
    double? outstandingAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus? status,
  });
  Future<void> deleteLoan(int id);
  Future<double> totalOutstanding();
}
