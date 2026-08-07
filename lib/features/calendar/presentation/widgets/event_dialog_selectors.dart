import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/overflow_choice_selector.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/widgets/event_dialog_helpers.dart';
import 'package:flutter/material.dart';

class EventPrioritySelector extends StatelessWidget {
  const EventPrioritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CalendarEventPriority selected;
  final ValueChanged<CalendarEventPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CalendarEventPriority.values.map((priority) {
        final option = eventPriorityOption(priority);
        final isSelected = selected == priority;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority == CalendarEventPriority.urgent ? 0 : 8,
            ),
            child: AppButton(
              label: option.label,
              size: AppButtonSize.sm,
              variant: AppButtonVariant.secondary,
              backgroundColor:
                  isSelected ? option.color : option.color.withValues(alpha: 0.12),
              foregroundColor: isSelected ? AppColors.textPrimary : option.color,
              fullWidth: true,
              onPressed: () => onChanged(priority),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class EventTypeSelector extends StatelessWidget {
  const EventTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CalendarEventType selected;
  final ValueChanged<CalendarEventType> onChanged;

  @override
  Widget build(BuildContext context) {
    return OverflowChoiceSelector<CalendarEventType>(
      options: CalendarEventType.values,
      selected: selected,
      labelFor: (type) => eventTypeOption(type).label,
      iconFor: (type) => eventTypeOption(type).icon,
      onChanged: onChanged,
      hint: 'Select event type',
    );
  }
}
