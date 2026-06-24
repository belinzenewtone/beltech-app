import 'package:beltech/core/di/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferencesSection extends ConsumerWidget {
  const NotificationPreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabledState = ref.watch(notificationsEnabledProvider);
    final budgetAlertsState = ref.watch(budgetAlertsEnabledProvider);
    final dailyDigestState = ref.watch(dailyDigestEnabledProvider);
    final weeklyReviewState =
        ref.watch(weeklyReviewNotificationsEnabledProvider);
    final notificationWriteState =
        ref.watch(notificationPreferenceControllerProvider);

    final notificationsEnabled = notificationsEnabledState.valueOrNull ?? true;
    final budgetAlertsEnabled = budgetAlertsState.valueOrNull ?? true;
    final dailyDigestEnabled = dailyDigestState.valueOrNull ?? true;
    final weeklyReviewEnabled = weeklyReviewState.valueOrNull ?? true;

    final readOnly = notificationsEnabledState.isLoading ||
        budgetAlertsState.isLoading ||
        dailyDigestState.isLoading ||
        weeklyReviewState.isLoading ||
        notificationWriteState.isLoading;
    final childPreferencesReadOnly = readOnly || !notificationsEnabled;

    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notifications'),
          subtitle: const Text('Enable task and event reminders'),
          value: notificationsEnabled,
          onChanged: readOnly
              ? null
              : (value) async {
                  await ref
                      .read(notificationPreferenceControllerProvider.notifier)
                      .setEnabled(value);
                },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Budget Alerts'),
          subtitle: const Text('Notify when spending nears or exceeds limits'),
          value: budgetAlertsEnabled,
          onChanged: childPreferencesReadOnly
              ? null
              : (value) async {
                  await ref
                      .read(notificationPreferenceControllerProvider.notifier)
                      .setBudgetAlertsEnabled(value);
                },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily Summary Digest'),
          subtitle:
              const Text('Send one daily summary after 7:00 AM local time'),
          value: dailyDigestEnabled,
          onChanged: childPreferencesReadOnly
              ? null
              : (value) async {
                  await ref
                      .read(notificationPreferenceControllerProvider.notifier)
                      .setDailyDigestEnabled(value);
                },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Weekly Review Ritual'),
          subtitle: const Text(
            'Send one Sunday evening ritual nudge based on your weekly signals',
          ),
          value: weeklyReviewEnabled,
          onChanged: childPreferencesReadOnly
              ? null
              : (value) async {
                  await ref
                      .read(notificationPreferenceControllerProvider.notifier)
                      .setWeeklyReviewEnabled(value);
                },
        ),
      ],
    );
  }
}
