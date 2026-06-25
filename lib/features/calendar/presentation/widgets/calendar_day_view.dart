import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
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
    final allDayEvents =
        events
            .where(
              (e) =>
                  e.endAt != null &&
                  e.endAt!.difference(e.startAt).inHours >= 23,
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final timedEvents =
        events
            .where(
              (e) =>
                  e.endAt == null ||
                  e.endAt!.difference(e.startAt).inHours < 23,
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_weekdayName(selectedDate.weekday)}, ${_monthDayLabel(selectedDate)}',
                  style: AppTypography.sectionTitle(context),
                ),
              ),
              if (_isToday(selectedDate))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'Today',
                    style: AppTypography.metaText(context).copyWith(
                      color: AppColors.accentLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (allDayEvents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All day',
                  style: AppTypography.bodySm(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...allDayEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _AllDayChip(
                      event: event,
                      onTap: () => onEventTap(event),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
                                style: AppTypography.bodySm(
                                  context,
                                ).copyWith(color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.borderSubtle.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final event in timedEvents)
                    _TimedPositioned(
                      event: event,
                      onTap: () => onEventTap(event),
                    ),
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
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _TimedPositioned extends StatelessWidget {
  const _TimedPositioned({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  int get _start => event.startAt.hour * 60 + event.startAt.minute;
  int get _end => event.endAt != null
      ? event.endAt!.hour * 60 + event.endAt!.minute
      : _start + 60;

  @override
  Widget build(BuildContext context) {
    final clampedStart = _start.clamp(360, 1260) - 360;
    final clampedEnd = _end.clamp(360, 1320) - 360;
    final top = clampedStart / 60 * CalendarDayView._hourRowHeight;
    final h =
        ((clampedEnd - clampedStart) / 60 * CalendarDayView._hourRowHeight)
            .clamp(28.0, double.infinity);
    final compact = h < 40;
    final typeColor = _eventColor(event.type);
    final startLabel =
        '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
    final endLabel = event.endAt != null
        ? '${event.endAt!.hour.toString().padLeft(2, '0')}:${event.endAt!.minute.toString().padLeft(2, '0')}'
        : null;

    return Positioned(
      top: top,
      left: CalendarDayView._hourLabelWidth + AppSpacing.sm,
      right: AppSpacing.sm,
      height: h,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            border: Border(left: BorderSide(color: typeColor, width: 3)),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact)
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.metaText(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (!compact && event.note != null && event.note!.isNotEmpty)
                Text(
                  event.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              Text(
                endLabel != null ? '$startLabel – $endLabel' : startLabel,
                style: AppTypography.bodySm(
                  context,
                ).copyWith(color: typeColor, fontWeight: FontWeight.w500),
              ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(left: BorderSide(color: typeColor, width: 3)),
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xs,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
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
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][weekday - 1];

String _monthDayLabel(DateTime date) =>
    '${date.day} ${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.month - 1]}';
