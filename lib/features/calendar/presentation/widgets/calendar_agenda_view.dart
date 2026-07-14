import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class CalendarAgendaView extends StatelessWidget {
  const CalendarAgendaView({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  final List<CalendarEvent> events;
  final void Function(CalendarEvent) onEventTap;

  static const List<String> _weekdays = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: AppEmptyState(
          icon: Icons.event_available_outlined,
          title: 'All clear',
          subtitle: 'No upcoming events in the next 30 days.',
          cardWrapped: false,
        ),
      );
    }

    final Map<DateTime, List<CalendarEvent>> grouped = {};
    for (final event in events) {
      final key = DateTime(
        event.startAt.year,
        event.startAt.month,
        event.startAt.day,
      );
      (grouped[key] ??= []).add(event);
    }
    final days = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in days) ...[
          _AgendaDayHeader(day: day),
          const SizedBox(height: AppSpacing.xs),
          for (final event in grouped[day]!)
            _AgendaEventRow(event: event, onTap: () => onEventTap(event)),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _AgendaDayHeader extends StatelessWidget {
  const _AgendaDayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final label = isToday
        ? 'Today'
        : '${CalendarAgendaView._weekdays[day.weekday]}, '
            '${CalendarAgendaView._months[day.month - 1]} ${day.day}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label,
        style: AppTypography.label(context).copyWith(
          color: isToday
              ? AppColors.accent
              : AppColors.textMutedFor(brightness),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _AgendaEventRow extends StatelessWidget {
  const _AgendaEventRow({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  static const Map<CalendarEventType, Color> _typeColors = {
    CalendarEventType.work: Color(0xFF4A90E2),
    CalendarEventType.personal: Color(0xFF7BC67E),
    CalendarEventType.health: Color(0xFFE57373),
    CalendarEventType.finance: Color(0xFFFFB74D),
    CalendarEventType.other: Color(0xFF90A4AE),
  };

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dotColor = _typeColors[event.type] ?? const Color(0xFF90A4AE);
    final timeLabel = event.allDay
        ? 'All day'
        : _formatTime(event.startAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTypography.bodyMd(context).copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    timeLabel,
                    style: AppTypography.metaText(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
