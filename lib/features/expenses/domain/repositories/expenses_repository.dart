import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/fee_analytics.dart';
import 'package:beltech/features/expenses/domain/entities/merchant_detail.dart';

abstract class ExpensesRepository {
  Stream<ExpensesSnapshot> watchSnapshot();

  Future<void> addManualTransaction({
    required String title,
    required String category,
    required double amountKes,
    DateTime? occurredAt,
  });

  Future<void> updateTransaction({
    required int transactionId,
    required String title,
    required String category,
    required double amountKes,
    required DateTime occurredAt,
  });

  Future<void> deleteTransaction(int transactionId);

  Future<int> importSmsMessages(List<String> rawMessages, {DateTime? from});

  Future<int> importFromDevice({DateTime? from});

  Future<ExpenseImportMetrics> fetchImportMetrics();

  Future<List<PaybillProfile>> fetchPaybillProfiles({int limit = 10});

  Future<List<FulizaLifecycleEvent>> fetchFulizaLifecycle({int limit = 12});

  Future<List<ExpenseReviewItem>> fetchReviewQueue({int limit = 20});

  Future<List<ExpenseQuarantineItem>> fetchQuarantineItems({int limit = 20});

  Future<int> replayImportQueue();

  Future<void> resolveReviewItem({
    required int reviewId,
    required bool approve,
  });

  Future<void> dismissQuarantineItem(int quarantineId);

  Future<MerchantDetail> fetchMerchantDetail(String merchantTitle);

  Future<FeeAnalytics> fetchFeeAnalytics();
}
