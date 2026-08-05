import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider lives in legacy.dart in Riverpod 3.x
import 'package:flutter_riverpod/legacy.dart';

final analyticsPeriodProvider = StateProvider<AnalyticsPeriod>(
  (_) => AnalyticsPeriod.week,
);

final analyticsSnapshotProvider = StreamProvider<AnalyticsSnapshot>(
  (ref) => ref
      .watch(analyticsRepositoryProvider)
      .watchSnapshot(ref.watch(analyticsPeriodProvider)),
);

/// Total spend for a specific year + month combination.
/// Family key: (year, month) e.g. (2024, 7).
final monthTotalSpendProvider =
    FutureProvider.family<double, (int year, int month)>(
  (ref, args) => ref
      .watch(analyticsRepositoryProvider)
      .getMonthTotalSpend(args.$1, args.$2),
);

/// Top spending category across all recorded transactions.
final topCategoryAllTimeProvider = FutureProvider<String?>(
  (ref) =>
      ref.watch(analyticsRepositoryProvider).getTopCategoryAllTime(),
);
