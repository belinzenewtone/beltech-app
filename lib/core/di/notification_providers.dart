import 'package:beltech/core/di/review_use_case_providers.dart';
import 'package:beltech/core/di/telemetry_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/di/feature_flag_providers.dart';
import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/core/notifications/notification_insights_service.dart';
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
}

final notificationPreferenceControllerProvider =
    AutoDisposeAsyncNotifierProvider<NotificationPreferenceController, void>(
  NotificationPreferenceController.new,
);
