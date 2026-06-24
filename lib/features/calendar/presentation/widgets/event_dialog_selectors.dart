import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/widgets/event_dialog_helpers.dart';
import 'package:flutter/material.dart';

class EventPrioritySelector extends StatelessWidget {
  const EventPrioritySelector({
    super.key,
    required this.selected,
    required this.textPrimary,
    required this.duration,
    required this.onChanged,
  });

  final CalendarEventPriority selected;
  final Color textPrimary;
  final Duration duration;
  final ValueChanged<CalendarEventPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        CalendarEventPriority.low,
        CalendarEventPriority.medium,
        CalendarEventPriority.high,
      ].map((priority) {
        final option = eventPriorityOption(priority);
        final isSelected = selected == priority;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority == CalendarEventPriority.low ? 8 : 0,
              left: priority == CalendarEventPriority.high ? 8 : 0,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onChanged(priority),
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? option.color.withValues(alpha: 0.9)
                      : option.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? option.color.withValues(alpha: 0.95)
                        : option.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? textPrimary
                        : option.color.withValues(alpha: 0.95),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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

class EventTypeSelector extends StatelessWidget {
  const EventTypeSelector({
    super.key,
    required this.selected,
    required this.textPrimary,
    required this.duration,
    required this.onChanged,
  });

  final CalendarEventType selected;
  final Color textPrimary;
  final Duration duration;
  final ValueChanged<CalendarEventType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CalendarEventType.values.map((type) {
        final option = eventTypeOption(type);
        final isSelected = selected == type;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? option.color.withValues(alpha: 0.88)
                  : option.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: option.color.withValues(alpha: isSelected ? 0.95 : 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option.icon,
                  size: 16,
                  color: isSelected
                      ? textPrimary
                      : option.color.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 6),
                Text(
                  option.label,
                  style: TextStyle(
                    color: isSelected
                        ? textPrimary
                        : option.color.withValues(alpha: 0.95),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
