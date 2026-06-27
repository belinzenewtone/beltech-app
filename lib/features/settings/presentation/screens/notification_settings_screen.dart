import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(notificationPreferenceControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(context, 'Unable to update notification settings.', ref: ref);
      }
    });

    final notificationsEnabledState = ref.watch(notificationsEnabledProvider);
    final budgetAlertsState = ref.watch(budgetAlertsEnabledProvider);
    final dailyDigestState = ref.watch(dailyDigestEnabledProvider);
    final dailyDigestTimeState = ref.watch(dailyDigestScheduleTimeProvider);
    final budgetThresholdsState = ref.watch(budgetAlertThresholdsProvider);
    final notificationWriteState = ref.watch(
      notificationPreferenceControllerProvider,
    );

    final notificationsEnabled = notificationsEnabledState.value ?? true;
    final budgetAlertsEnabled = budgetAlertsState.value ?? true;
    final dailyDigestEnabled = dailyDigestState.value ?? true;
    final (digestHour, digestMinute) =
        dailyDigestTimeState.value ?? (7, 0);
    final (budgetHigh, budgetMedium, budgetLow) =
        budgetThresholdsState.value ?? (90.0, 70.0, 50.0);

    final readOnly =
        notificationsEnabledState.isLoading ||
        budgetAlertsState.isLoading ||
        dailyDigestState.isLoading ||
        dailyDigestTimeState.isLoading ||
        budgetThresholdsState.isLoading ||
        notificationWriteState.isLoading;
    final childPreferencesReadOnly = readOnly || !notificationsEnabled;

    return SecondaryPageShell(
      title: 'Notifications',
      child: AppCard(
        tone: AppCardTone.muted,
        padding: EdgeInsets.zero,
        child: Column(
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
            _BudgetThresholdSliders(
              high: budgetHigh,
              medium: budgetMedium,
              low: budgetLow,
              enabled:
                  !childPreferencesReadOnly && budgetAlertsEnabled,
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
            _DigestTimeRow(
              hour: digestHour,
              minute: digestMinute,
              enabled: !childPreferencesReadOnly && dailyDigestEnabled,
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
          ],
        ),
      ),
    );
  }
}

class _BudgetThresholdSliders extends StatefulWidget {
  const _BudgetThresholdSliders({
    required this.high,
    required this.medium,
    required this.low,
    required this.onChanged,
    this.enabled = true,
  });

  final double high;
  final double medium;
  final double low;
  final bool enabled;
  final void Function(double high, double medium, double low) onChanged;

  @override
  State<_BudgetThresholdSliders> createState() =>
      _BudgetThresholdSlidersState();
}

class _BudgetThresholdSlidersState extends State<_BudgetThresholdSliders> {
  late double _high;
  late double _medium;
  late double _low;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _high = widget.high;
    _medium = widget.medium;
    _low = widget.low;
  }

  @override
  void didUpdateWidget(_BudgetThresholdSliders old) {
    super.didUpdateWidget(old);
    if (!_dragging) {
      _high = widget.high;
      _medium = widget.medium;
      _low = widget.low;
    }
  }

  void _update(double high, double medium, double low) {
    setState(() {
      _high = high;
      _medium = medium;
      _low = low;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert thresholds',
            style: AppTypography.label(context).copyWith(
              color: widget.enabled ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          _ThresholdSlider(
            label: 'Critical',
            value: _high,
            enabled: widget.enabled,
            onChanged: (value) {
              _dragging = true;
              _update(value, _medium, _low);
            },
            onChangeEnd: (value) {
              _dragging = false;
              widget.onChanged(value, _medium, _low);
            },
          ),
          const SizedBox(height: 8),
          _ThresholdSlider(
            label: 'Warning',
            value: _medium,
            enabled: widget.enabled,
            onChanged: (value) {
              _dragging = true;
              _update(_high, value, _low);
            },
            onChangeEnd: (value) {
              _dragging = false;
              widget.onChanged(_high, value, _low);
            },
          ),
          const SizedBox(height: 8),
          _ThresholdSlider(
            label: 'Info',
            value: _low,
            enabled: widget.enabled,
            onChanged: (value) {
              _dragging = true;
              _update(_high, _medium, value);
            },
            onChangeEnd: (value) {
              _dragging = false;
              widget.onChanged(_high, _medium, value);
            },
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
    this.onChangeEnd,
    this.enabled = true,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: AppTypography.bodySm(context).copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 10,
            max: 100,
            divisions: 9,
            activeColor: enabled ? AppColors.accent : AppColors.border,
            inactiveColor: AppColors.border,
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? onChangeEnd : null,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: AppTypography.bodySm(context).copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
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
    this.enabled = true,
  });

  final int hour;
  final int minute;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: enabled ? onTap : null,
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
                    ).copyWith(
                      color: enabled
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: AppTypography.cardTitle(context).copyWith(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.access_time_rounded,
              color: enabled ? AppColors.textMuted : AppColors.border,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
