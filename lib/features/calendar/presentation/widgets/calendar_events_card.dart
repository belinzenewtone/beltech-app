import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class CalendarEventsCard extends StatelessWidget {
  const CalendarEventsCard({
    super.key,
    required this.events,
    required this.busy,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CalendarEvent> events;
  final bool busy;
  final Future<void> Function(CalendarEvent event) onComplete;
  final Future<void> Function(CalendarEvent event) onEdit;
  final Future<void> Function(CalendarEvent event) onDelete;

  @override
  Widget build(BuildContext context) {
    final swipeDuration = AppMotion.swipe(context);
    final resizeDuration = AppMotion.resize(context);

    if (events.isEmpty) {
      return const AppEmptyState(
        icon: Icons.event_outlined,
        title: 'No events',
        subtitle: 'Tap the Add button to create one.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final event = events[index];
        final start =
            '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
        final end = event.endAt == null
            ? null
            : '${event.endAt!.hour.toString().padLeft(2, '0')}:${event.endAt!.minute.toString().padLeft(2, '0')}';
        final typeColor = _typeColor(event.type);
        final timeLabel = end == null ? start : '$start – $end';

        return Dismissible(
          key: ValueKey('event-${event.id}'),
          direction: busy ? DismissDirection.none : DismissDirection.horizontal,
          movementDuration: swipeDuration,
          resizeDuration: resizeDuration,
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.4,
            DismissDirection.endToStart: 0.4,
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await onComplete(event);
              return false;
            }
            if (direction == DismissDirection.endToStart) {
              await onDelete(event);
              return false;
            }
            return false;
          },
          background: const _EventSwipeBackground(
            color: AppColors.successMuted,
            icon: Icons.check_circle_outline,
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: const _EventSwipeBackground(
            color: AppColors.dangerMuted,
            icon: Icons.delete_outline,
            alignment: Alignment.centerRight,
          ),
          child: AppCard(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: event.completed
                          ? AppColors.textMuted
                          : typeColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    event.completed
                        ? Icons.check_circle
                        : _typeIcon(event.type),
                    color: event.completed ? AppColors.success : typeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMd(context).copyWith(
                            color: event.completed
                                ? AppColors.textMuted
                                : null,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (event.note != null && event.note!.isNotEmpty)
                          Text(
                            event.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm(context),
                          ),
                        Text(
                          timeLabel,
                          style: AppTypography.bodySm(
                            context,
                          ).copyWith(color: typeColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => onEdit(event),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: events.length,
    );
  }
}

Color _typeColor(CalendarEventType type) {
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

IconData _typeIcon(CalendarEventType type) {
  return switch (type) {
    CalendarEventType.work => Icons.work_outline,
    CalendarEventType.personal => Icons.person_outline,
    CalendarEventType.finance => Icons.account_balance_wallet_outlined,
    CalendarEventType.health => Icons.favorite_outline,
    CalendarEventType.general => Icons.event_note_outlined,
    CalendarEventType.birthday => Icons.cake_outlined,
    CalendarEventType.anniversary => Icons.celebration_outlined,
    CalendarEventType.countdown => Icons.timer_outlined,
  };
}

class _EventSwipeBackground extends StatelessWidget {
  const _EventSwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: alignment,
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}
