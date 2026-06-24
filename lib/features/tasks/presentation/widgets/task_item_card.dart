import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final secondaryText = AppColors.textSecondaryFor(brightness);
    final swipeDuration = AppMotion.swipe(context);
    final resizeDuration = AppMotion.resize(context);
    final priorityColor = taskPriorityColor(task.priority);
    final countdownBadge = _buildCountdownBadge(task);

    final activeEntryAsync = ref.watch(activeTimerProvider(task.id));
    final tick = ref.watch(timerTickProvider).valueOrNull ?? DateTime.now();
    final isTimerRunning = activeEntryAsync.valueOrNull?.isRunning ?? false;
    final Duration elapsed = isTimerRunning && activeEntryAsync.value != null
        ? tick.difference(activeEntryAsync.value!.startedAt!)
        : Duration.zero;
    final elapsedText =
        isTimerRunning ? _formatElapsed(elapsed) : null;

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
        semanticsLabel: 'Swipe action: mark task complete',
      ),
      secondaryBackground: const TaskSwipeBackground(
        color: AppColors.dangerMuted,
        icon: Icons.delete_outline,
        alignment: Alignment.centerRight,
        semanticsLabel: 'Swipe action: delete task',
      ),
      child: GlassCard(
        tone: selectionMode && selected
            ? GlassCardTone.accent
            : GlassCardTone.standard,
        accentColor: selectionMode && selected ? AppColors.accent : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(GlassStyles.borderRadius),
          onTap: selectionMode ? onSelectToggle : null,
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
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: selectionMode
                      ? (selected ? 'Deselect task' : 'Select task')
                      : (task.completed ? 'Mark incomplete' : 'Mark complete'),
                  onPressed: busy
                      ? null
                      : () {
                          AppHaptics.lightImpact();
                          if (selectionMode) {
                            onSelectToggle();
                            return;
                          }
                          onToggle();
                        },
                  icon: Icon(
                    selectionMode
                        ? (selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded)
                        : (task.completed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked),
                    color: selectionMode
                        ? (selected ? AppColors.accent : secondaryText)
                        : (task.completed ? AppColors.success : secondaryText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: textTheme.bodyLarge?.copyWith(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          AppCapsule(
                            label: _priorityLabel(task.priority),
                            color: priorityColor,
                            variant: AppCapsuleVariant.subtle,
                            size: AppCapsuleSize.sm,
                          ),
                          if (countdownBadge != null)
                            countdownBadge
                          else if (task.completed)
                            const AppCapsule(
                              label: 'Completed',
                              color: AppColors.success,
                              variant: AppCapsuleVariant.subtle,
                              size: AppCapsuleSize.sm,
                              icon: Icons.check_rounded,
                            )
                          else if (task.dueDate != null)
                            AppCapsule(
                              label: _formatDate(task.dueDate!),
                              color: secondaryText,
                              variant: AppCapsuleVariant.subtle,
                              size: AppCapsuleSize.sm,
                              icon: Icons.schedule_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!selectionMode) ...[
                  if (elapsedText != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Center(
                        child: Text(
                          elapsedText,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: isTimerRunning ? 'Stop timer' : 'Start timer',
                    onPressed: busy
                        ? null
                        : () {
                            AppHaptics.lightImpact();
                            ref
                                .read(timerControllerProvider(task.id).notifier)
                                .toggleTimer();
                          },
                    icon: Icon(
                      isTimerRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    color: isTimerRunning ? AppColors.accent : null,
                  ),
                  IconButton(
                    tooltip: 'Edit task',
                    onPressed: busy
                        ? null
                        : () {
                            onEdit();
                          },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildCountdownBadge(TaskItem task) {
    if (task.completed || task.dueDate == null) {
      return null;
    }

    final now = DateTime.now();
    final due = task.dueDate!;
    final difference = due.difference(now);

    if (difference.isNegative) {
      // Overdue
      final days = (-difference.inDays).abs();
      final label = days == 0 ? 'Due today' : '${days}d overdue';
      return AppCapsule(
        label: label,
        color: AppColors.danger,
        variant: AppCapsuleVariant.subtle,
        size: AppCapsuleSize.sm,
        icon: Icons.warning_amber_rounded,
      );
    } else if (difference.inDays == 0) {
      // Due today
      return const AppCapsule(
        label: 'Today',
        color: AppColors.warning,
        variant: AppCapsuleVariant.subtle,
        size: AppCapsuleSize.sm,
        icon: Icons.schedule_rounded,
      );
    } else if (difference.inHours < 3 && difference.inHours > 0) {
      // Due in less than 3 hours
      final hours = difference.inHours;
      return AppCapsule(
        label: 'In ${hours}h',
        color: AppColors.warning,
        variant: AppCapsuleVariant.subtle,
        size: AppCapsuleSize.sm,
        icon: Icons.schedule_rounded,
      );
    } else if (difference.inDays == 1) {
      // Due tomorrow
      return const AppCapsule(
        label: 'Tomorrow',
        color: AppColors.accent,
        variant: AppCapsuleVariant.subtle,
        size: AppCapsuleSize.sm,
        icon: Icons.event_rounded,
      );
    }

    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }

    return DateFormat('MMM d').format(date);
  }

  String _priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => 'Urgent',
      TaskPriority.medium => 'Important',
      TaskPriority.low => 'Neutral',
    };
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
