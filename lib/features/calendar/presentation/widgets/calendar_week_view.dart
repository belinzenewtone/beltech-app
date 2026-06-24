import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();
    final selectedEvents = events
        .where((e) => _sameDate(e.startAt, selectedDay))
        .toList()
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
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(_weekdayName(selectedDay.weekday), style: textTheme.titleMedium)),
                Text(_monthDayLabel(selectedDay),
                    style: textTheme.bodySmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              if (selectedEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No events', style: TextStyle(color: AppColors.textSecondary))),
                )
              else
                ...selectedEvents.map((event) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _WeekEventCard(event: event, onTap: () => onEventTap(event)),
                    )),
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
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(header,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.accent : Colors.transparent,
              border: !isSelected && isToday ? Border.all(color: AppColors.accentLight, width: 1.5) : null,
            ),
            alignment: Alignment.center,
            child: Text('$day',
                style: textTheme.bodyMedium?.copyWith(
                  color: isSelected ? AppColors.textPrimary : isToday ? AppColors.accentLight : AppColors.textPrimary,
                  fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
          const SizedBox(height: 4),
          if (hasEvents) const _Dot(color: AppColors.accentLight) else const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _WeekEventCard extends StatelessWidget {
  const _WeekEventCard({required this.event, required this.onTap});
  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final typeColor = _eventColor(event.type);
    final time =
        '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        tone: GlassCardTone.muted,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 4, height: 36, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(AppRadius.md))),
          const SizedBox(width: 10),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                        decoration: event.completed ? TextDecoration.lineThrough : null)),
                if (event.note != null && event.note!.isNotEmpty)
                  Text(event.note!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

Color _eventColor(CalendarEventType type) => switch (type) {
      CalendarEventType.work => AppColors.accent,
      CalendarEventType.personal => AppColors.violet,
      CalendarEventType.finance => AppColors.teal,
      CalendarEventType.health => AppColors.warning,
      CalendarEventType.general => AppColors.slate,
      CalendarEventType.birthday => AppColors.warning,
      CalendarEventType.anniversary => AppColors.danger,
      CalendarEventType.countdown => AppColors.accent,
    };

bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayName(int weekday) => const [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ][weekday - 1];

String _monthDayLabel(DateTime date) => '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.day}';
