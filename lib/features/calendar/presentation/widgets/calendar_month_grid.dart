import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    super.key,
    required this.visibleMonth,
    required this.selectedDay,
    required this.eventTypes,
    required this.taskDays,
    required this.maxWidth,
    required this.onSelect,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final Map<int, CalendarEventType> eventTypes;
  final Set<int> taskDays;
  final double maxWidth;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalDays = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final leadingBlanks =
        DateTime(visibleMonth.year, visibleMonth.month, 1).weekday - 1;
    final totalItems = ((leadingBlanks + totalDays + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GridView.builder(
          itemCount: totalItems,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 42,
          ),
          itemBuilder: (context, index) {
            final day = index - leadingBlanks + 1;
            if (day < 1 || day > totalDays) {
              return const SizedBox.shrink();
            }

            final current = DateTime(
              visibleMonth.year,
              visibleMonth.month,
              day,
            );
            final isSelected =
                selectedDay.year == current.year &&
                selectedDay.month == current.month &&
                selectedDay.day == current.day;
            final isToday =
                today.year == current.year &&
                today.month == current.month &&
                today.day == current.day;
            final eventType = eventTypes[day];
            final hasEvents = eventType != null;
            final hasTasks = taskDays.contains(day);

            return Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onSelect(current),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    border: !isSelected && isToday
                        ? Border.all(color: AppColors.accentLight, width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: textTheme.bodyLarge?.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : isToday
                              ? AppColors.accentLight
                              : AppColors.textPrimary,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      if (hasEvents || hasTasks)
                        Positioned(
                          bottom: 5,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasEvents)
                                _MarkerDot(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : _eventTypeColor(eventType),
                                ),
                              if (hasEvents && hasTasks)
                                const SizedBox(width: 4),
                              if (hasTasks)
                                _MarkerDot(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.teal,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

Color _eventTypeColor(CalendarEventType type) {
  return switch (type) {
    CalendarEventType.work => AppColors.accent,
    CalendarEventType.personal => AppColors.violet,
    CalendarEventType.finance => AppColors.teal,
    CalendarEventType.health => AppColors.warning,
    CalendarEventType.general => AppColors.slate,
    CalendarEventType.birthday => AppColors.warning,
    CalendarEventType.anniversary => AppColors.danger,
    CalendarEventType.countdown => AppColors.accent,
  };
}
