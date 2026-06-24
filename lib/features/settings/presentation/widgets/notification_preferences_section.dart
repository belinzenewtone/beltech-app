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
    final dailyDigestTimeState = ref.watch(dailyDigestScheduleTimeProvider);
    final budgetThresholdsState = ref.watch(budgetAlertThresholdsProvider);
    final notificationWriteState =
        ref.watch(notificationPreferenceControllerProvider);

    final notificationsEnabled = notificationsEnabledState.valueOrNull ?? true;
    final budgetAlertsEnabled = budgetAlertsState.valueOrNull ?? true;
    final dailyDigestEnabled = dailyDigestState.valueOrNull ?? true;
    final weeklyReviewEnabled = weeklyReviewState.valueOrNull ?? true;
    final (digestHour, digestMinute) = dailyDigestTimeState.valueOrNull ?? (7, 0);
    final (budgetHigh, budgetMedium, budgetLow) =
        budgetThresholdsState.valueOrNull ?? (90.0, 70.0, 50.0);

    final readOnly = notificationsEnabledState.isLoading ||
        budgetAlertsState.isLoading ||
        dailyDigestState.isLoading ||
        weeklyReviewState.isLoading ||
        dailyDigestTimeState.isLoading ||
        budgetThresholdsState.isLoading ||
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
        if (budgetAlertsEnabled && !childPreferencesReadOnly)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Alert Thresholds',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                _buildThresholdSlider(
                  context,
                  'Critical Alert (High)',
                  budgetHigh,
                  (value) async {
                    await ref
                        .read(notificationPreferenceControllerProvider.notifier)
                        .setBudgetAlertThresholds(value, budgetMedium, budgetLow);
                  },
                ),
                const SizedBox(height: 8),
                _buildThresholdSlider(
                  context,
                  'Warning (Medium)',
                  budgetMedium,
                  (value) async {
                    await ref
                        .read(notificationPreferenceControllerProvider.notifier)
                        .setBudgetAlertThresholds(budgetHigh, value, budgetLow);
                  },
                ),
                const SizedBox(height: 8),
                _buildThresholdSlider(
                  context,
                  'Info (Low)',
                  budgetLow,
                  (value) async {
                    await ref
                        .read(notificationPreferenceControllerProvider.notifier)
                        .setBudgetAlertThresholds(budgetHigh, budgetMedium, value);
                  },
                ),
              ],
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily Summary Digest'),
          subtitle: Text('Send one daily summary at ${digestHour.toString().padLeft(2, '0')}:${digestMinute.toString().padLeft(2, '0')}'),
          value: dailyDigestEnabled,
          onChanged: childPreferencesReadOnly
              ? null
              : (value) async {
                  await ref
                      .read(notificationPreferenceControllerProvider.notifier)
                      .setDailyDigestEnabled(value);
                },
        ),
        if (dailyDigestEnabled && !childPreferencesReadOnly)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Digest Time'),
              subtitle: Text(
                '${digestHour.toString().padLeft(2, '0')}:${digestMinute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: digestHour, minute: digestMinute),
                );
                if (picked != null) {
                  await ref
                      .read(notificationPreferenceControllerProvider.notifier)
                      .setDailyDigestScheduleTime(picked.hour, picked.minute);
                }
              },
            ),
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

  Widget _buildThresholdSlider(
    BuildContext context,
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 10,
                max: 100,
                divisions: 9,
                label: '${value.toStringAsFixed(0)}%',
                onChanged: onChanged,
              ),
            ),
            Text('${value.toStringAsFixed(0)}%'),
          ],
        ),
      ],
    );
  }
}
