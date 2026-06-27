import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.events,
    required this.onDayTap,
    required this.onEventTap,
  });

  final DateTime weekStart;
  final DateTime selectedDay;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<CalendarEvent> onEventTap;

  static const _dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selectedEvents =
        events.where((e) => _sameDate(e.startAt, selectedDay)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final date = weekStart.add(Duration(days: i));
              final isToday = _sameDate(date, today);
              final isSelected = _sameDate(date, selectedDay);
              return SizedBox(
                width: 38,
                child: _DayCell(
                  header: _dayHeaders[i],
                  day: date.day,
                  isToday: isToday,
                  isSelected: isSelected,
                  hasEvents: events.any((e) => _sameDate(e.startAt, date)),
                  onTap: () => onDayTap(date),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _weekdayName(selectedDay.weekday),
                      style: AppTypography.cardTitle(context),
                    ),
                  ),
                  Text(
                    _monthDayLabel(selectedDay),
                    style: AppTypography.label(
                      context,
                    ).copyWith(color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (selectedEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No events',
                      style: AppTypography.bodySm(context),
                    ),
                  ),
                )
              else
                ...selectedEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _WeekEventCard(
                      event: event,
                      onTap: () => onEventTap(event),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.header,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.onTap,
  });

  final String header;
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(header, style: AppTypography.label(context)),
          const SizedBox(height: AppSpacing.xs),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.accent : Colors.transparent,
              border: !isSelected && isToday
                  ? Border.all(color: AppColors.accentLight, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
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
          ),
          const SizedBox(height: AppSpacing.xs),
          if (hasEvents)
            const _Dot(color: AppColors.accentLight)
          else
            const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSpacing.xs,
    height: AppSpacing.xs,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _WeekEventCard extends StatelessWidget {
  const _WeekEventCard({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = _eventColor(event);
    final time =
        '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        tone: AppCardTone.muted,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xs,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd(context).copyWith(
                      decoration: event.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (event.note != null && event.note!.isNotEmpty)
                    Text(
                      event.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(context),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(time, style: AppTypography.bodySm(context)),
          ],
        ),
      ),
    );
  }
}

Color _eventColor(CalendarEvent event) {
  if (event.kind != CalendarEventKind.event) {
    return switch (event.kind) {
      CalendarEventKind.birthday => AppColors.warning,
      CalendarEventKind.anniversary => AppColors.danger,
      CalendarEventKind.countdown => AppColors.accent,
      CalendarEventKind.event => AppColors.slate,
    };
  }
  return switch (event.type) {
    CalendarEventType.work => AppColors.accent,
    CalendarEventType.personal => AppColors.violet,
    CalendarEventType.finance => AppColors.teal,
    CalendarEventType.health => AppColors.warning,
    CalendarEventType.other => AppColors.slate,
  };
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayName(int weekday) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][weekday - 1];

String _monthDayLabel(DateTime date) =>
    '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.day}';
