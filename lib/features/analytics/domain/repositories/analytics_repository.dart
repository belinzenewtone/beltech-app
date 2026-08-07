import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';

/// A single transaction row belonging to a category (for the drill-down list).
class CategoryTransaction {
  const CategoryTransaction({
    required this.id,
    required this.title,
    required this.amountKes,
    required this.occurredAt,
    this.feeKes,
  });

  final int id;
  final String title;
  final double amountKes;
  final DateTime occurredAt;
  final double? feeKes;
}

abstract class AnalyticsRepository {
  Stream<AnalyticsSnapshot> watchSnapshot(AnalyticsPeriod period);

  /// Total spend in a specific calendar month of a specific year.
  /// Used for the "vs same period last year" comparison toggle.
  Future<double> getMonthTotalSpend(int year, int month);

  /// Top category by total spend across all time.
  Future<String?> getTopCategoryAllTime();

  /// Transactions belonging to [category] (expenses only), newest first.
  Future<List<CategoryTransaction>> getCategoryTransactions(
    String category, {
    DateTime? start,
    DateTime? end,
  });
}
