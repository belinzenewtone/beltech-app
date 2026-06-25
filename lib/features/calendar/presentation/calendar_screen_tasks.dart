part of 'calendar_screen.dart';

class _CalendarTasksPane extends StatelessWidget {
  const _CalendarTasksPane({
    required this.state,
    required this.selectedDay,
    required this.tasksState,
  });

  final _CalendarScreenState state;
  final DateTime selectedDay;
  final AsyncValue<List<TaskItem>> tasksState;

  @override
  Widget build(BuildContext context) {
    return tasksState.when(
      skipLoadingOnReload: true,
      data: (tasks) {
        final dayTasks =
            tasks
                .where(
                  (task) =>
                      task.dueDate != null &&
                      _isSameDate(task.dueDate!, selectedDay),
                )
                .toList(growable: false)
              ..sort((left, right) {
                final dueCompare = (left.dueDate ?? selectedDay).compareTo(
                  right.dueDate ?? selectedDay,
                );
                if (dueCompare != 0) {
                  return dueCompare;
                }
                if (left.completed == right.completed) {
                  return left.id.compareTo(right.id);
                }
                return left.completed ? 1 : -1;
              });

        final query = state._searchQuery;
        final visibleTasks = dayTasks
            .where((task) {
              if (!state._showCompletedTasks && task.completed) {
                return false;
              }
              if (query.isEmpty) return true;
              final haystack = '${task.title} ${task.description ?? ''}'
                  .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);

        if (visibleTasks.isEmpty) {
          return AppEmptyState(
            icon: Icons.task_alt_outlined,
            title: dayTasks.isEmpty ? 'No tasks' : 'Nothing found',
            subtitle: dayTasks.isEmpty
                ? 'Tap Add to create one.'
                : 'Try a different search or tap Show done.',
          );
        }

        return Column(
          children: visibleTasks
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    tone: AppCardTone.muted,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: task.completed,
                          onChanged: (_) async {
                            await state.ref
                                .read(taskWriteControllerProvider.notifier)
                                .toggleTask(
                                  taskId: task.id,
                                  completed: !task.completed,
                                );
                            if (context.mounted &&
                                !state.ref
                                    .read(taskWriteControllerProvider)
                                    .hasError) {
                              AppFeedback.success(
                                context,
                                task.completed
                                    ? 'Task marked as pending'
                                    : 'Task completed ✓',
                                ref: state.ref,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: AppTypography.bodyMd(context).copyWith(
                                  decoration: task.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (task.description != null &&
                                  task.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    task.description!,
                                    style: AppTypography.bodySm(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _editTaskWithSuperSheetImpl(state, context, task),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () async {
                            await state.ref
                                .read(taskWriteControllerProvider.notifier)
                                .deleteTask(task.id);
                            if (context.mounted &&
                                !state.ref
                                    .read(taskWriteControllerProvider)
                                    .hasError) {
                              AppFeedback.success(
                                context,
                                'Task deleted',
                                ref: state.ref,
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => Column(
        children: List.generate(3, (_) => AppSkeleton.card(context))
            .expand(
              (element) => [
                element,
                const SizedBox(height: AppSpacing.listGap),
              ],
            )
            .toList(),
      ),
      error: (_, __) => ErrorMessage(
        label: 'Unable to load tasks',
        onRetry: () => state.ref.invalidate(tasksProvider),
      ),
    );
  }
}
