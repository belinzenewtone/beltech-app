import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/loans/data/repositories/loans_repository_impl.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late LoansRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = LoansRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('addLoan and loadLoans persist correctly', () async {
    await repository.addLoan(
      name: 'Car Loan',
      lender: 'Bank A',
      totalAmount: 100000,
      outstandingAmount: 75000,
      interestRate: 12.5,
      status: LoanStatus.active,
    );

    final loans = await repository.loadLoans();
    expect(loans.length, 1);
    expect(loans.first.name, 'Car Loan');
    expect(loans.first.lender, 'Bank A');
    expect(loans.first.totalAmount, 100000);
    expect(loans.first.outstandingAmount, 75000);
    expect(loans.first.interestRate, 12.5);
    expect(loans.first.status, LoanStatus.active);
  });

  test('updateLoan and deleteLoan work correctly', () async {
    await repository.addLoan(
      name: 'Personal',
      totalAmount: 20000,
      outstandingAmount: 20000,
    );

    final created = await repository.loadLoans();
    final loan = created.first;

    await repository.updateLoan(
      id: loan.id,
      outstandingAmount: 15000,
      status: LoanStatus.cleared,
    );
    final updated = await repository.loadLoans();
    expect(updated.first.outstandingAmount, 15000);
    expect(updated.first.status, LoanStatus.cleared);

    await repository.deleteLoan(loan.id);
    final afterDelete = await repository.loadLoans();
    expect(afterDelete, isEmpty);
  });

  test('totalOutstanding sums active loans only', () async {
    await repository.addLoan(
      name: 'A',
      totalAmount: 10000,
      outstandingAmount: 5000,
      status: LoanStatus.active,
    );
    await repository.addLoan(
      name: 'B',
      totalAmount: 20000,
      outstandingAmount: 0,
      status: LoanStatus.cleared,
    );
    await repository.addLoan(
      name: 'C',
      totalAmount: 30000,
      outstandingAmount: 10000,
      status: LoanStatus.active,
    );

    final total = await repository.totalOutstanding();
    expect(total, 15000);
  });
}
