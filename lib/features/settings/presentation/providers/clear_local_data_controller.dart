import 'dart:async';

import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/security_providers.dart';
import 'package:beltech/core/theme/theme_mode_controller.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for the destructive "Clear all local data" action.
///
/// Wipes every local persistence layer in the app:
/// - SharedPreferences (settings, flags, telemetry)
/// - FlutterSecureStorage (credentials, biometric flag)
/// - Main Drift database (transactions, tasks, events, budgets, etc.)
/// - Assistant profile database
/// - Scheduled local notifications
///
/// This is local-only; there is no cloud recovery.
class ClearLocalDataController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}

  Future<void> clearAll() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final secureStorage = ref.read(flutterSecureStorageProvider);
      await secureStorage.deleteAll();

      final appStore = ref.read(appDriftStoreProvider);
      await appStore.resetAllData();

      final profileStore = ref.read(assistantProfileStoreProvider);
      await profileStore.resetProfileData();

      final notificationService = ref.read(localNotificationServiceProvider);
      await notificationService.cancelAllReminders();

      // Force downstream UI to re-read defaults.
      ref.invalidate(authProvider);
      ref.invalidate(sessionLockSettingsProvider);
      ref.invalidate(themeModeControllerProvider);
      ref.invalidate(notificationsEnabledProvider);
      ref.invalidate(budgetAlertsEnabledProvider);
      ref.invalidate(dailyDigestEnabledProvider);
      ref.invalidate(weeklyReviewNotificationsEnabledProvider);
      ref.invalidate(dailyDigestScheduleTimeProvider);
      ref.invalidate(budgetAlertThresholdsProvider);
      ref.invalidate(doNotDisturbHoursProvider);
    });
  }
}

final clearLocalDataControllerProvider =
    AutoDisposeAsyncNotifierProvider<ClearLocalDataController, void>(
      ClearLocalDataController.new,
    );
