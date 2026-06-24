import 'package:beltech/core/theme/app_colors.dart';
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
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
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: allowClear && value != null
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : const Icon(Icons.schedule_rounded),
        ),
        child: Text(text),
      ),
    );
  }
}

class SuperAddPrioritySelector extends StatelessWidget {
  const SuperAddPrioritySelector({
    super.key,
    required this.selected,
    required this.textPrimary,
    required this.duration,
    required this.onChanged,
  });

  final SuperEntryPriority? selected;
  final Color textPrimary;
  final Duration duration;
  final ValueChanged<SuperEntryPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SuperEntryPriority.values.map((priority) {
        final selectedState = priority == selected;
        final color = switch (priority) {
          SuperEntryPriority.high => AppColors.danger,
          SuperEntryPriority.medium => AppColors.warning,
          SuperEntryPriority.low => AppColors.accent,
        };
        final label = switch (priority) {
          SuperEntryPriority.high => 'Urgent',
          SuperEntryPriority.medium => 'Important',
          SuperEntryPriority.low => 'Neutral',
        };
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority == SuperEntryPriority.low ? 0 : 4,
              left: priority == SuperEntryPriority.high ? 0 : 4,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(priority),
              child: AnimatedContainer(
                duration: duration,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedState ? color : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedState ? color : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedState ? Colors.white : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
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
    required this.duration,
    required this.onChanged,
  });

  final SuperEntryEventType? selected;
  final Duration duration;
  final ValueChanged<SuperEntryEventType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SuperEntryEventType.values.map((item) {
        final selectedState = item == selected;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(item),
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selectedState ? AppColors.accent : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selectedState ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              item.name[0].toUpperCase() + item.name.substring(1),
              style: TextStyle(
                color: selectedState ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final base = value ?? fallbackDate ?? DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          firstDate: DateTime(base.year - 100),
          lastDate: DateTime(base.year + 50),
          initialDate: base,
        );
        if (pickedDate == null || !context.mounted) return;
        onPick(
          DateTime(pickedDate.year, pickedDate.month, pickedDate.day),
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(text),
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
    final years = List.generate(currentYear - 1900 + 1, (i) => 1900 + i).reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birth year (optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Not set'),
              selected: selectedYear == null,
              onSelected: (_) => onChanged(null),
            ),
            ...years.take(10).map((year) => ChoiceChip(
                  label: Text('$year'),
                  selected: selectedYear == year,
                  onSelected: (_) => onChanged(year),
                )),
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
    return Row(
      children: [
        Expanded(
          child: Text(
            'Repeat yearly',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
        ),
      ],
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
    return Row(
      children: [
        Expanded(
          child: Text(
            'Remind 3 days before',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class SuperAddReminderMinutesSelector extends StatelessWidget {
  const SuperAddReminderMinutesSelector({
    super.key,
    required this.selectedMinutes,
    required this.duration,
    required this.onChanged,
  });

  final int? selectedMinutes;
  final Duration duration;
  final ValueChanged<int> onChanged;

  static const List<int> _presetMinutes = [0, 5, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder lead time',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetMinutes.map((minutes) {
            final selected = minutes == selectedMinutes;
            final label = minutes == 0 ? 'At time' : '${minutes}m before';
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(minutes),
              child: AnimatedContainer(
                duration: duration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
