import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class CalendarDayView extends StatelessWidget {
  const CalendarDayView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onEventTap,
  });

  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onEventTap;

  static const _startHour = 6;
  static const _endHour = 22;
  static const _hourRowHeight = 56.0;
  static const _hourLabelWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allDayEvents = events
        .where((e) => e.endAt != null && e.endAt!.difference(e.startAt).inHours >= 23)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final timedEvents = events
        .where((e) => e.endAt == null || e.endAt!.difference(e.startAt).inHours < 23)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_weekdayName(selectedDate.weekday)}, ${_monthDayLabel(selectedDate)}',
                  style: textTheme.titleMedium,
                ),
              ),
              if (_isToday(selectedDate))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Text('Today',
                      style: TextStyle(color: AppColors.accentLight, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        if (allDayEvents.isNotEmpty) ...[
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All day',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...allDayEvents.map((event) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _AllDayChip(event: event, onTap: () => onEventTap(event)),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: (_endHour - _startHour) * _hourRowHeight,
              child: Stack(
                children: [
                  for (int i = 0; i < _endHour - _startHour; i++)
                    Positioned(
                      top: i * _hourRowHeight,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: _hourRowHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: _hourLabelWidth,
                              child: Text(
                                '${(_startHour + i).toString().padLeft(2, '0')}:00',
                                style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Container(
                                    height: 1, color: AppColors.borderSubtle.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    ),
                  for (final event in timedEvents)
                    _TimedPositioned(event: event, onTap: () => onEventTap(event)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _TimedPositioned extends StatelessWidget {
  const _TimedPositioned({required this.event, required this.onTap});
  final CalendarEvent event;
  final VoidCallback onTap;

  int get _start => event.startAt.hour * 60 + event.startAt.minute;
  int get _end => event.endAt != null ? event.endAt!.hour * 60 + event.endAt!.minute : _start + 60;

  @override
  Widget build(BuildContext context) {
    final clampedStart = _start.clamp(360, 1260) - 360;
    final clampedEnd = _end.clamp(360, 1320) - 360;
    final top = clampedStart / 60 * CalendarDayView._hourRowHeight;
    final h = ((clampedEnd - clampedStart) / 60 * CalendarDayView._hourRowHeight).clamp(28.0, double.infinity);
    final compact = h < 40;
    final typeColor = _eventColor(event.type);
    final startLabel = '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
    final endLabel = event.endAt != null
        ? '${event.endAt!.hour.toString().padLeft(2, '0')}:${event.endAt!.minute.toString().padLeft(2, '0')}'
        : null;

    return Positioned(
      top: top,
      left: CalendarDayView._hourLabelWidth + 8,
      right: 8,
      height: h,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.18),
            border: Border(left: BorderSide(color: typeColor, width: 3)),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact)
                Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 12)),
              if (!compact && event.note != null && event.note!.isNotEmpty)
                Text(event.note!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text(endLabel != null ? '$startLabel – $endLabel' : startLabel,
                  style: TextStyle(color: typeColor, fontSize: compact ? 10 : 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.event, required this.onTap});
  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = _eventColor(event.type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(left: BorderSide(color: typeColor, width: 3)),
        ),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
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

String _weekdayName(int weekday) => const [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ][weekday - 1];

String _monthDayLabel(DateTime date) => '${date.day} ${const [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ][date.month - 1]}';
