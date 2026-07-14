part of 'tasks_screen.dart';

class _TasksLayout extends StatelessWidget {
  const _TasksLayout({
    required this.state,
    required this.tasksState,
    required this.allTasks,
    required this.writeState,
    required this.countSubtitle,
  });

  final _TasksScreenState state;
  final AsyncValue<List<TaskItem>> tasksState;
  final List<TaskItem> allTasks;
  final AsyncValue<void> writeState;
  final String countSubtitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageShell(
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Tasks',
                subtitle: countSubtitle,
              ),
              const SizedBox(height: AppSpacing.md),
              AppSearchBar(
                controller: state._searchController,
                hint: 'Search tasks',
                onChanged: (_) => state._refreshSearchResults(),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Expanded(
                child: tasksState.when(
                  data: (tasks) {
                    final query = state._searchController.text.trim();
                    final filtered = _filterForQuery(tasks, query);
                    if (filtered.isEmpty) {
                      return const SizedBox(
                        width: double.infinity,
                        child: AppEmptyState(
                          icon: Icons.task_alt_rounded,
                          title: 'No open tasks',
                          subtitle:
                              'Create a task to start your daily focus list.',
                        ),
                      );
                    }
                    return ListView(
                      children: [
                        ..._buildPriorityGroups(
                          context,
                          filtered.where((t) => !t.completed).toList(),
                        ),
                        ..._buildCompletedGroup(
                          context,
                          filtered.where((t) => t.completed).toList(),
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    children: List.generate(5, (_) => const TaskCardSkeleton())
                        .expand(
                          (element) => [
                            element,
                            const SizedBox(height: AppSpacing.listGap),
                          ],
                        )
                        .toList(),
                  ),
                  error: (_, _) => ErrorMessage(
                    label: 'Unable to load tasks',
                    onRetry: () => state.ref.invalidate(filteredTasksProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: AppSpacing.fabBottom(context),
          child: AppFab(
            label: 'Add task',
            busy: writeState.isLoading,
            onPressed: () => _handleSuperAddFromTasksImpl(state, context),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPriorityGroups(BuildContext context, List<TaskItem> pending) {
    if (pending.isEmpty) return const [];
    final priorityOrder = [
      TaskPriority.urgent,
      TaskPriority.important,
      TaskPriority.neutral,
    ];
    final grouped = {
      for (final p in priorityOrder)
        p: pending.where((t) => t.priority == p).toList(),
    };
    final labelColor = {
      TaskPriority.urgent: AppColors.danger,
      TaskPriority.important: AppColors.warning,
      TaskPriority.neutral: AppColors.textSecondary,
    };

    return priorityOrder.expand((priority) {
      final group = grouped[priority]!;
      if (group.isEmpty) return const <Widget>[];
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            priority.label,
            style: AppTypography.sectionTitle(context).copyWith(
              color: labelColor[priority],
            ),
          ),
        ),
        ...group.map((task) => _taskCard(context, task)),
        const SizedBox(height: AppSpacing.sectionGap),
      ];
    }).toList();
  }

  List<Widget> _buildCompletedGroup(BuildContext context, List<TaskItem> completed) {
    if (completed.isEmpty) return const [];
    final shown = completed.take(20).toList();
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          'Completed',
          style: AppTypography.sectionTitle(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
      ...shown.map((task) => _taskCard(context, task)),
    ];
  }

  Widget _taskCard(BuildContext context, TaskItem task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
      child: TaskItemCard(
        task: task,
        selectionMode: false,
        selected: false,
        onSelectToggle: () {},
        busy: writeState.isLoading,
        onToggle: () async {
          final isCompleting = !task.completed;
          await state.ref
              .read(taskWriteControllerProvider.notifier)
              .toggleTask(
                taskId: task.id,
                completed: isCompleting,
              );
          if (context.mounted &&
              !state.ref.read(taskWriteControllerProvider).hasError) {
            AppFeedback.success(
              context,
              isCompleting ? 'Task completed ✓' : 'Task marked as pending',
              ref: state.ref,
            );
          }
        },
        onEdit: () async {
          await state._editTask(context, task);
        },
        onDelete: () async {
          final deletedTask = task;
          AppHaptics.mediumImpact();
          await state.ref
              .read(taskWriteControllerProvider.notifier)
              .deleteTask(deletedTask.id);
          if (!context.mounted) {
            return;
          }
          if (state.ref.read(taskWriteControllerProvider).hasError) {
            return;
          }
          state.ref.read(toastProvider.notifier).showWithUndo(
            'Task deleted',
            onUndo: () async {
              await state.ref
                  .read(taskWriteControllerProvider.notifier)
                  .addTask(
                    title: deletedTask.title,
                    description: deletedTask.description,
                    deadline: deletedTask.deadline,
                    priority: deletedTask.priority,
                    reminderOffsets: deletedTask.reminderOffsets,
                    alarmEnabled: deletedTask.alarmEnabled,
                  );
            },
          );
        },
      ),
    );
  }

  List<TaskItem> _filterForQuery(List<TaskItem> tasks, String query) {
    if (query.isEmpty) return tasks;
    final trimmed = query.toLowerCase();
    return tasks.where((task) {
      return task.title.toLowerCase().contains(trimmed) ||
          (task.description?.toLowerCase().contains(trimmed) ?? false);
    }).toList();
  }
}
