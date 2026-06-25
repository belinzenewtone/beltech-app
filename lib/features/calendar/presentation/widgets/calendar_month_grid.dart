import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
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
            final isSelected = _sameDate(current, selectedDay);
            final isToday = _sameDate(current, today);
            final hasActivity =
                eventTypes.containsKey(day) || taskDays.contains(day);

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
                        style: AppTypography.bodyMd(context).copyWith(
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
                      if (hasActivity && !isSelected)
                        Positioned(
                          bottom: AppSpacing.xs,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
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

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
