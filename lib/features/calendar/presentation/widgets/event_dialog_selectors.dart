import 'package:beltech/core/widgets/app_button.dart';
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
              right: priority == CalendarEventPriority.high ? 0 : 8,
            ),
            child: AppButton(
              label: option.label,
              size: AppButtonSize.sm,
              variant: isSelected
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CalendarEventType.values.map((type) {
        final option = eventTypeOption(type);
        final isSelected = selected == type;
        return AppButton(
          label: option.label,
          icon: option.icon,
          size: AppButtonSize.sm,
          variant: isSelected
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: () => onChanged(type),
        );
      }).toList(),
    );
  }
}
