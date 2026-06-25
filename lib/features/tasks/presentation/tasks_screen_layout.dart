part of 'tasks_screen.dart';

class _TasksLayout extends StatelessWidget {
  const _TasksLayout({
    required this.state,
    required this.tasksState,
    required this.allTasks,
    required this.selectedFilter,
    required this.writeState,
    required this.countSubtitle,
  });

  final _TasksScreenState state;
  final AsyncValue<List<TaskItem>> tasksState;
  final List<TaskItem> allTasks;
  final TaskFilter selectedFilter;
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
                eyebrow: 'FOCUS',
                title: 'Tasks',
                subtitle: countSubtitle,
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state._selectionMode)
                      IconButton(
                        tooltip: allTasks.isEmpty
                            ? 'Select all'
                            : state._selectedTaskIds.length == allTasks.length
                            ? 'Clear selection'
                            : 'Select all',
                        onPressed: writeState.isLoading || allTasks.isEmpty
                            ? null
                            : () => state._toggleSelectAll(allTasks),
                        icon: Icon(
                          state._selectedTaskIds.length == allTasks.length
                              ? Icons.deselect_rounded
                              : Icons.select_all_rounded,
                        ),
                      ),
                    IconButton(
                      tooltip: state._selectionMode
                          ? 'Exit multi-select'
                          : 'Select multiple tasks',
                      onPressed: writeState.isLoading
                          ? null
                          : state._toggleSelectionMode,
                      icon: Icon(
                        state._selectionMode
                            ? Icons.close_rounded
                            : Icons.checklist_rtl_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSearchBar(
                controller: state._searchController,
                hint: 'Search tasks',
                onChanged: (_) => state._refreshSearchResults(),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (state._selectionMode) ...[
                TaskSelectionBar(
                  selectedCount: state._selectedTaskIds.length,
                  isLoading: writeState.isLoading,
                  onComplete: () => state._completeSelected(context),
                  onArchive: () => state._archiveSelected(context),
                  onDelete: () => state._deleteSelected(context),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: TaskFilter.values.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: state._filterLabel(filter),
                        selected: selectedFilter == filter,
                        onTap: () {
                          state.ref.read(taskFilterProvider.notifier).state =
                              filter;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Expanded(
                child: tasksState.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.task_alt_rounded,
                        title: 'No open tasks',
                        subtitle:
                            'Create a task to start your daily focus list.',
                      );
                    }
                    return ListView.separated(
                      itemBuilder: (_, index) => TaskItemCard(
                        task: tasks[index],
                        selectionMode: state._selectionMode,
                        selected: state._selectedTaskIds.contains(
                          tasks[index].id,
                        ),
                        onSelectToggle: () =>
                            state._toggleTaskSelection(tasks[index].id),
                        busy: writeState.isLoading,
                        onToggle: () async {
                          if (state._selectionMode) {
                            state._toggleTaskSelection(tasks[index].id);
                            return;
                          }
                          final isCompleting = !tasks[index].completed;
                          await state.ref
                              .read(taskWriteControllerProvider.notifier)
                              .toggleTask(
                                taskId: tasks[index].id,
                                completed: isCompleting,
                              );
                          if (context.mounted &&
                              !state.ref
                                  .read(taskWriteControllerProvider)
                                  .hasError) {
                            AppFeedback.success(
                              context,
                              isCompleting
                                  ? 'Task completed ✓'
                                  : 'Task marked as pending',
                              ref: state.ref,
                            );
                          }
                        },
                        onEdit: () async {
                          await state._editTask(context, tasks[index]);
                        },
                        onDelete: () async {
                          if (state._selectionMode) {
                            state._toggleTaskSelection(tasks[index].id);
                            return;
                          }
                          final deletedTask = tasks[index];
                          AppHaptics.mediumImpact();
                          await state.ref
                              .read(taskWriteControllerProvider.notifier)
                              .deleteTask(deletedTask.id);
                          if (!context.mounted) {
                            return;
                          }
                          if (state.ref
                              .read(taskWriteControllerProvider)
                              .hasError) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          if (messenger == null) {
                            return;
                          }
                          messenger.hideCurrentSnackBar();
                          final keyboardInset =
                              MediaQuery.maybeOf(context)?.viewInsets.bottom ??
                              0;
                          final snackResult = await messenger
                              .showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Task deleted',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {},
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    88 + keyboardInset,
                                  ),
                                  duration: const Duration(seconds: 4),
                                ),
                              )
                              .closed;
                          if (snackResult == SnackBarClosedReason.action &&
                              context.mounted) {
                            await state.ref
                                .read(taskWriteControllerProvider.notifier)
                                .addTask(
                                  title: deletedTask.title,
                                  description: deletedTask.description,
                                  dueDate: deletedTask.dueDate,
                                  priority: deletedTask.priority,
                                );
                          }
                        },
                      ),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.listGap),
                      itemCount: tasks.length,
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
                  error: (_, __) => ErrorMessage(
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
}
