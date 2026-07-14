import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/super_add_sheet_models.dart';
import 'package:flutter/material.dart';

class SuperAddWhenPickerRow extends StatelessWidget {
  const SuperAddWhenPickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.allowClear,
    required this.onPick,
    required this.onClear,
    this.fallbackDate,
  });

  final String label;
  final DateTime? value;
  final bool allowClear;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;
  final DateTime? fallbackDate;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final text = value == null
        ? 'Not set'
        : '${localizations.formatMediumDate(value!)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value!), alwaysUse24HourFormat: true)}';
    return AppCard(
      tone: AppCardTone.muted,
      onTap: () async {
        final base = value ?? fallbackDate ?? DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          firstDate: DateTime(base.year - 2),
          lastDate: DateTime(base.year + 5),
          initialDate: base,
        );
        if (pickedDate == null || !context.mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(base),
        );
        if (pickedTime == null) return;
        onPick(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
      },
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySm(context)),
                const SizedBox(height: 2),
                Text(text, style: AppTypography.bodyMd(context)),
              ],
            ),
          ),
          if (allowClear && value != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            )
          else
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class SuperAddPrioritySelector extends StatelessWidget {
  const SuperAddPrioritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SuperEntryPriority? selected;
  final ValueChanged<SuperEntryPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SuperEntryPriority.values.map((priority) {
        final selectedState = priority == selected;
        final label = switch (priority) {
          SuperEntryPriority.high => 'Urgent',
          SuperEntryPriority.medium => 'Important',
          SuperEntryPriority.low => 'Neutral',
        };
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority == SuperEntryPriority.low ? 0 : 8,
            ),
            child: AppButton(
              label: label,
              size: AppButtonSize.sm,
              variant: selectedState
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => onChanged(priority),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SuperAddEventTypeSelector extends StatelessWidget {
  const SuperAddEventTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SuperEntryEventType? selected;
  final ValueChanged<SuperEntryEventType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: SuperEntryEventType.values.map((item) {
          final selectedState = item == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppButton(
              label: item.name[0].toUpperCase() + item.name.substring(1),
              size: AppButtonSize.sm,
              variant: selectedState
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              onPressed: () => onChanged(item),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SuperAddDateOnlyPickerRow extends StatelessWidget {
  const SuperAddDateOnlyPickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
    this.fallbackDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final DateTime? fallbackDate;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final text = value == null
        ? 'Not set'
        : localizations.formatMediumDate(value!);
    return AppCard(
      tone: AppCardTone.muted,
      onTap: () async {
        final base = value ?? fallbackDate ?? DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          firstDate: DateTime(base.year - 100),
          lastDate: DateTime(base.year + 50),
          initialDate: base,
        );
        if (pickedDate == null || !context.mounted) return;
        onPick(DateTime(pickedDate.year, pickedDate.month, pickedDate.day));
      },
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySm(context)),
                const SizedBox(height: 2),
                Text(text, style: AppTypography.bodyMd(context)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class SuperAddYearSelector extends StatelessWidget {
  const SuperAddYearSelector({
    super.key,
    required this.selectedYear,
    required this.onChanged,
  });

  final int? selectedYear;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1900 + 1,
      (i) => 1900 + i,
    ).reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Birth year', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton(
              label: 'Not set',
              size: AppButtonSize.sm,
              variant: selectedYear == null
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              onPressed: () => onChanged(null),
            ),
            ...years
                .take(10)
                .map(
                  (year) => AppButton(
                    label: '$year',
                    size: AppButtonSize.sm,
                    variant: selectedYear == year
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                    onPressed: () => onChanged(year),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class SuperAddRepeatToggle extends StatelessWidget {
  const SuperAddRepeatToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      child: Row(
        children: [
          Expanded(
            child: Text('Repeat yearly', style: AppTypography.bodyMd(context)),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class SuperAddRemind3DaysToggle extends StatelessWidget {
  const SuperAddRemind3DaysToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Remind 3 days before',
              style: AppTypography.bodyMd(context),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class SuperAddReminderOffsetsSelector extends StatelessWidget {
  const SuperAddReminderOffsetsSelector({
    super.key,
    required this.selectedOffsets,
    required this.onToggle,
  });

  final List<int> selectedOffsets;
  final ValueChanged<int> onToggle;

  static const List<int> _presetMinutes = [
    0,
    5,
    10,
    15,
    30,
    60,
    60 * 24,
    60 * 24 * 2,
    60 * 24 * 7,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presetMinutes.map((minutes) {
        final selected = selectedOffsets.contains(minutes);
        final label = switch (minutes) {
          0 => 'At time',
          5 => '5 min before',
          10 => '10 min before',
          15 => '15 min before',
          30 => '30 min before',
          60 => '1 hour before',
          1440 => '1 day before',
          2880 => '2 days before',
          10080 => '1 week before',
          _ => '${minutes}m before',
        };
        return AppButton(
          label: label,
          size: AppButtonSize.sm,
          variant: selected
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: () => onToggle(minutes),
        );
      }).toList(),
    );
  }
}
