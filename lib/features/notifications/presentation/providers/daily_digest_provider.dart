import 'package:beltech/features/notifications/data/services/daily_digest_worker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the daily digest worker service.
final dailyDigestWorkerProvider = Provider((ref) {
  return DailyDigestWorker(null);
});
