import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferencesSection extends ConsumerWidget {
  const NotificationPreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabledState = ref.watch(notificationsEnabledProvider);
    final budgetAlertsState = ref.watch(budgetAlertsEnabledProvider);
    final dailyDigestState = ref.watch(dailyDigestEnabledProvider);
    final weeklyReviewState = ref.watch(
      weeklyReviewNotificationsEnabledProvider,
    );
    final dailyDigestTimeState = ref.watch(dailyDigestScheduleTimeProvider);
    final budgetThresholdsState = ref.watch(budgetAlertThresholdsProvider);
    final notificationWriteState = ref.watch(
      notificationPreferenceControllerProvider,
    );

    final notificationsEnabled = notificationsEnabledState.valueOrNull ?? true;
    final budgetAlertsEnabled = budgetAlertsState.valueOrNull ?? true;
    final dailyDigestEnabled = dailyDigestState.valueOrNull ?? true;
    final weeklyReviewEnabled = weeklyReviewState.valueOrNull ?? true;
    final (digestHour, digestMinute) =
        dailyDigestTimeState.valueOrNull ?? (7, 0);
    final (budgetHigh, budgetMedium, budgetLow) =
        budgetThresholdsState.valueOrNull ?? (90.0, 70.0, 50.0);

    final readOnly =
        notificationsEnabledState.isLoading ||
        budgetAlertsState.isLoading ||
        dailyDigestState.isLoading ||
        weeklyReviewState.isLoading ||
        dailyDigestTimeState.isLoading ||
        budgetThresholdsState.isLoading ||
        notificationWriteState.isLoading;
    final childPreferencesReadOnly = readOnly || !notificationsEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsRow(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Task and event reminders',
          trailing: Switch.adaptive(
            value: notificationsEnabled,
            onChanged: readOnly
                ? null
                : (value) async {
                    await ref
                        .read(notificationPreferenceControllerProvider.notifier)
                        .setEnabled(value);
                  },
          ),
          isFirst: true,
        ),
        SettingsRow(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Budget Alerts',
          subtitle: 'Notify when spending nears limits',
          trailing: Switch.adaptive(
            value: budgetAlertsEnabled,
            onChanged: childPreferencesReadOnly
                ? null
                : (value) async {
                    await ref
                        .read(notificationPreferenceControllerProvider.notifier)
                        .setBudgetAlertsEnabled(value);
                  },
          ),
          dividerAbove: true,
        ),
        if (budgetAlertsEnabled && !childPreferencesReadOnly)
          _BudgetThresholdSliders(
            high: budgetHigh,
            medium: budgetMedium,
            low: budgetLow,
            onChanged: (high, medium, low) async {
              await ref
                  .read(notificationPreferenceControllerProvider.notifier)
                  .setBudgetAlertThresholds(high, medium, low);
            },
          ),
        SettingsRow(
          icon: Icons.today_outlined,
          title: 'Daily Summary',
          subtitle:
              'One digest at ${digestHour.toString().padLeft(2, '0')}:${digestMinute.toString().padLeft(2, '0')}',
          trailing: Switch.adaptive(
            value: dailyDigestEnabled,
            onChanged: childPreferencesReadOnly
                ? null
                : (value) async {
                    await ref
                        .read(notificationPreferenceControllerProvider.notifier)
                        .setDailyDigestEnabled(value);
                  },
          ),
          dividerAbove: true,
        ),
        if (dailyDigestEnabled && !childPreferencesReadOnly)
          _DigestTimeRow(
            hour: digestHour,
            minute: digestMinute,
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
        SettingsRow(
          icon: Icons.calendar_today_outlined,
          title: 'Weekly Review',
          subtitle: 'Sunday evening ritual nudge',
          trailing: Switch.adaptive(
            value: weeklyReviewEnabled,
            onChanged: childPreferencesReadOnly
                ? null
                : (value) async {
                    await ref
                        .read(notificationPreferenceControllerProvider.notifier)
                        .setWeeklyReviewEnabled(value);
                  },
          ),
          dividerAbove: true,
          isLast: true,
        ),
      ],
    );
  }
}

class _BudgetThresholdSliders extends StatelessWidget {
  const _BudgetThresholdSliders({
    required this.high,
    required this.medium,
    required this.low,
    required this.onChanged,
  });

  final double high;
  final double medium;
  final double low;
  final void Function(double high, double medium, double low) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alert thresholds', style: AppTypography.label(context)),
          const SizedBox(height: 12),
          _ThresholdSlider(
            label: 'Critical',
            value: high,
            onChanged: (value) => onChanged(value, medium, low),
          ),
          const SizedBox(height: 8),
          _ThresholdSlider(
            label: 'Warning',
            value: medium,
            onChanged: (value) => onChanged(high, value, low),
          ),
          const SizedBox(height: 8),
          _ThresholdSlider(
            label: 'Info',
            value: low,
            onChanged: (value) => onChanged(high, medium, value),
          ),
        ],
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: AppTypography.bodySm(context)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 10,
            max: 100,
            divisions: 9,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            label: '${value.toStringAsFixed(0)}%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: AppTypography.bodySm(context),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _DigestTimeRow extends StatelessWidget {
  const _DigestTimeRow({
    required this.hour,
    required this.minute,
    required this.onTap,
  });

  final int hour;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 4, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Digest time',
                    style: AppTypography.body(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(time, style: AppTypography.cardTitle(context)),
                ],
              ),
            ),
            const Icon(
              Icons.access_time_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
