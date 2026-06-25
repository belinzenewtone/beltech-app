import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';

class ManageExpenseImportReviewUseCase {
  const ManageExpenseImportReviewUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<ExpenseImportMetrics> fetchMetrics() =>
      _repository.fetchImportMetrics();

  Future<List<ExpenseReviewItem>> fetchReviewQueue({int limit = 20}) =>
      _repository.fetchReviewQueue(limit: limit);

  Future<List<ExpenseQuarantineItem>> fetchQuarantine({int limit = 20}) =>
      _repository.fetchQuarantineItems(limit: limit);

  Future<void> resolveReviewItem({
    required int reviewId,
    required bool approve,
  }) => _repository.resolveReviewItem(reviewId: reviewId, approve: approve);

  Future<void> dismissQuarantineItem(int quarantineId) =>
      _repository.dismissQuarantineItem(quarantineId);
}
