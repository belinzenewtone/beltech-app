import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';

abstract class AnalyticsRepository {
  Stream<AnalyticsSnapshot> watchSnapshot(AnalyticsPeriod period);

  /// Total spend in a specific calendar month of a specific year.
  /// Used for the "vs same period last year" comparison toggle.
  Future<double> getMonthTotalSpend(int year, int month);

  /// Top category by total spend across all time.
  Future<String?> getTopCategoryAllTime();
}
