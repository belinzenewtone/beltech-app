import 'package:beltech/core/di/review_use_case_providers.dart';
import 'package:beltech/core/di/telemetry_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/di/feature_flag_providers.dart';
import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/core/notifications/notification_insights_service.dart';
import 'package:beltech/features/notifications/data/services/daily_digest_worker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (_) => LocalNotificationService(),
);

final notificationsEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(localNotificationServiceProvider).isNotificationsEnabled(),
);

final notificationInsightsServiceProvider =
    Provider<NotificationInsightsService>(
  (ref) => NotificationInsightsService(
    ref.watch(localNotificationServiceProvider),
    ref.watch(budgetRepositoryProvider),
    ref.watch(expensesRepositoryProvider),
    ref.watch(incomeRepositoryProvider),
    ref.watch(tasksRepositoryProvider),
    ref.watch(calendarRepositoryProvider),
    ref.watch(analyticsRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(buildWeekReviewDataUseCaseProvider),
    ref.watch(buildWeekReviewRitualUseCaseProvider),
    ref.watch(revampTelemetryServiceProvider),
    ref.watch(featureFlagStoreProvider),
  ),
);

final budgetAlertsEnabledProvider = FutureProvider<bool>(
  (ref) =>
      ref.watch(notificationInsightsServiceProvider).isBudgetAlertsEnabled(),
);

final dailyDigestEnabledProvider = FutureProvider<bool>(
  (ref) =>
      ref.watch(notificationInsightsServiceProvider).isDailyDigestEnabled(),
);

final weeklyReviewNotificationsEnabledProvider = FutureProvider<bool>(
  (ref) =>
      ref.watch(notificationInsightsServiceProvider).isWeeklyReviewEnabled(),
);

final dailyDigestScheduleTimeProvider = FutureProvider<(int, int)>(
  (ref) => ref.watch(localNotificationServiceProvider).getDailyDigestScheduleTime(),
);

final budgetAlertThresholdsProvider = FutureProvider<(double, double, double)>(
  (ref) => ref.watch(localNotificationServiceProvider).getBudgetAlertThresholds(),
);

final doNotDisturbHoursProvider = FutureProvider<(int, int)>(
  (ref) => ref.watch(localNotificationServiceProvider).getDoNotDisturbHours(),
);

class NotificationPreferenceController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(localNotificationServiceProvider)
          .setNotificationsEnabled(enabled);
      await ref.read(revampTelemetryServiceProvider).track(
        'notifications_enabled_changed',
        attributes: {'enabled': enabled},
      );
      ref.invalidate(notificationsEnabledProvider);
    });
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(notificationInsightsServiceProvider)
          .setBudgetAlertsEnabled(enabled);
      await ref.read(revampTelemetryServiceProvider).track(
        'budget_alerts_setting_changed',
        attributes: {'enabled': enabled},
      );
      ref.invalidate(budgetAlertsEnabledProvider);
    });
  }

  Future<void> setDailyDigestEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(notificationInsightsServiceProvider)
          .setDailyDigestEnabled(enabled);
      await ref.read(revampTelemetryServiceProvider).track(
        'daily_digest_setting_changed',
        attributes: {'enabled': enabled},
      );
      ref.invalidate(dailyDigestEnabledProvider);
    });
  }

  Future<void> setWeeklyReviewEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(notificationInsightsServiceProvider)
          .setWeeklyReviewEnabled(enabled);
      await ref.read(revampTelemetryServiceProvider).track(
        'weekly_review_setting_changed',
        attributes: {'enabled': enabled},
      );
      ref.invalidate(weeklyReviewNotificationsEnabledProvider);
    });
  }

  Future<void> setDailyDigestScheduleTime(int hour, int minute) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(localNotificationServiceProvider)
          .setDailyDigestScheduleTime(hour, minute);
      await ref.read(revampTelemetryServiceProvider).track(
        'daily_digest_schedule_changed',
        attributes: {'hour': hour, 'minute': minute},
      );
      ref.invalidate(dailyDigestScheduleTimeProvider);
    });
  }

  Future<void> setBudgetAlertThresholds(double high, double medium, double low) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(localNotificationServiceProvider)
          .setBudgetAlertThresholds(high, medium, low);
      await ref.read(revampTelemetryServiceProvider).track(
        'budget_alert_thresholds_changed',
        attributes: {'high': high, 'medium': medium, 'low': low},
      );
      ref.invalidate(budgetAlertThresholdsProvider);
    });
  }

  Future<void> setDoNotDisturbHours(int startHour, int endHour) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(localNotificationServiceProvider)
          .setDoNotDisturbHours(startHour, endHour);
      await ref.read(revampTelemetryServiceProvider).track(
        'dnd_hours_changed',
        attributes: {'start_hour': startHour, 'end_hour': endHour},
      );
      ref.invalidate(doNotDisturbHoursProvider);
    });
  }
}

final notificationPreferenceControllerProvider =
    AutoDisposeAsyncNotifierProvider<NotificationPreferenceController, void>(
  NotificationPreferenceController.new,
);

final dailyDigestWorkerProvider = Provider((ref) {
  return const DailyDigestWorker();
});
