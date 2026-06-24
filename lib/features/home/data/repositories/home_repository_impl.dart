import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:beltech/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<HomeOverview> watchOverview() {
    return _store.watchHomeOverview().map(
          (record) => HomeOverview(
            todayKes: record.todayKes,
            weekKes: record.weekKes,
            completedCount: record.completedCount,
            pendingCount: record.pendingCount,
            upcomingEventsCount: record.upcomingEventsCount,
            weeklySpendingKes: record.weeklySpendingKes,
            recentTransactions: record.recentTransactions
                .map(
                  (tx) => HomeTransaction(
                    title: tx.title,
                    category: tx.category,
                    amountKes: tx.amountKes,
                  ),
                )
                .toList(),
          ),
        );
  }
}
