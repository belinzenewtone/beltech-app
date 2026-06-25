import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';

abstract class AnalyticsRepository {
  Stream<AnalyticsSnapshot> watchSnapshot();
}
