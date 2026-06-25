import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/presentation/providers/time_tracking_providers.dart';
import 'package:beltech/features/tasks/presentation/widgets/task_item_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TaskItemCard extends ConsumerWidget {
  const TaskItemCard({
    super.key,
    required this.task,
    required this.selectionMode,
    required this.selected,
    required this.onSelectToggle,
    required this.onToggle,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onSelectToggle;
  final Future<void> Function() onToggle;
  final bool busy;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final secondaryText = AppColors.textSecondaryFor(brightness);
    final swipeDuration = AppMotion.swipe(context);
    final resizeDuration = AppMotion.resize(context);
    final priorityColor = taskPriorityColor(task.priority);

    final activeEntryAsync = ref.watch(activeTimerProvider(task.id));
    final tick = ref.watch(timerTickProvider).valueOrNull ?? DateTime.now();
    final isTimerRunning = activeEntryAsync.valueOrNull?.isRunning ?? false;
    final elapsed = isTimerRunning && activeEntryAsync.value != null
        ? tick.difference(activeEntryAsync.value!.startedAt!)
        : Duration.zero;
    final elapsedText = isTimerRunning ? _formatElapsed(elapsed) : null;

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: busy || selectionMode
          ? DismissDirection.none
          : DismissDirection.horizontal,
      movementDuration: swipeDuration,
      resizeDuration: resizeDuration,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.4,
        DismissDirection.endToStart: 0.4,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await onToggle();
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          await onDelete();
          return false;
        }
        return false;
      },
      background: const TaskSwipeBackground(
        color: AppColors.successMuted,
        icon: Icons.check_circle_outline,
        alignment: Alignment.centerLeft,
        semanticsLabel: 'Mark task complete',
      ),
      secondaryBackground: const TaskSwipeBackground(
        color: AppColors.dangerMuted,
        icon: Icons.delete_outline,
        alignment: Alignment.centerRight,
        semanticsLabel: 'Delete task',
      ),
      child: AppCard(
        tone: selectionMode && selected
            ? AppCardTone.accent
            : AppCardTone.standard,
        accentColor: selectionMode && selected ? AppColors.accent : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: busy
              ? null
              : () {
                  if (selectionMode) {
                    onSelectToggle();
                    return;
                  }
                  onEdit();
                },
          onLongPress: busy
              ? null
              : () {
                  AppHaptics.lightImpact();
                  onSelectToggle();
                },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!task.completed) ...[
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else
                  const SizedBox(width: 4),
                _StatusCircle(
                  completed: task.completed,
                  selected: selectionMode && selected,
                  onTap: busy
                      ? null
                      : () {
                          AppHaptics.lightImpact();
                          if (selectionMode) {
                            onSelectToggle();
                            return;
                          }
                          onToggle();
                        },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.title,
                        style: AppTypography.cardTitle(context).copyWith(
                          color: task.completed
                              ? secondaryText
                              : AppColors.textPrimaryFor(brightness),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(task),
                        style: AppTypography.bodySm(
                          context,
                        ).copyWith(color: _subtitleColor(context, task)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!selectionMode)
                  _TimerButton(
                    isRunning: isTimerRunning,
                    elapsedText: elapsedText,
                    busy: busy,
                    onToggle: () {
                      AppHaptics.lightImpact();
                      ref
                          .read(timerControllerProvider(task.id).notifier)
                          .toggleTimer();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(TaskItem task) {
    if (task.dueDate != null) {
      return _formatDate(task.dueDate!);
    }
    if (task.description != null && task.description!.isNotEmpty) {
      return task.description!;
    }
    return 'No deadline';
  }

  Color _subtitleColor(BuildContext context, TaskItem task) {
    if (task.dueDate != null && !task.completed) {
      final now = DateTime.now();
      final due = task.dueDate!;
      if (due.isBefore(now)) {
        return AppColors.danger;
      }
    }
    return AppColors.textSecondaryFor(Theme.of(context).brightness);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'today, ${DateFormat('h:mm a').format(date)}';
    }
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'tomorrow, ${DateFormat('h:mm a').format(date)}';
    }

    return DateFormat('MMM d, h:mm a').format(date);
  }

  String _formatElapsed(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({
    required this.completed,
    required this.selected,
    this.onTap,
  });

  final bool completed;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = selected
        ? AppColors.accent
        : completed
        ? AppColors.accent
        : AppColors.surfaceMutedFor(brightness);
    final borderColor = selected || completed
        ? AppColors.accent
        : AppColors.borderFor(brightness);
    final tooltip = selected
        ? 'Deselect'
        : completed
        ? 'Mark incomplete'
        : 'Mark complete';

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: selected || completed
                ? null
                : Border.all(color: borderColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  const _TimerButton({
    required this.isRunning,
    required this.elapsedText,
    required this.busy,
    required this.onToggle,
  });

  final bool isRunning;
  final String? elapsedText;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (elapsedText != null)
          Text(
            elapsedText!,
            style: AppTypography.bodySm(context).copyWith(
              color: AppColors.accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        IconButton(
          tooltip: isRunning ? 'Stop timer' : 'Start timer',
          onPressed: busy ? null : onToggle,
          icon: Icon(
            isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 20,
          ),
          color: isRunning ? AppColors.accent : null,
        ),
      ],
    );
  }
}
