part of 'tasks_screen.dart';

Future<void> _completeSelectedImpl(
  _TasksScreenState state,
  BuildContext context,
) async {
  final ids = state._selectedTaskIds.toList(growable: false);
  if (ids.isEmpty) {
    return;
  }
  final count = await state.ref
      .read(taskWriteControllerProvider.notifier)
      .completeTasks(ids);
  if (!context.mounted) {
    return;
  }
  if (!state.ref.read(taskWriteControllerProvider).hasError) {
    AppFeedback.success(
      context,
      count == 1 ? '1 task completed' : '$count tasks completed',
      ref: state.ref,
    );
    state._clearSelectionState();
  }
}

Future<void> _archiveSelectedImpl(
  _TasksScreenState state,
  BuildContext context,
) async {
  final ids = state._selectedTaskIds.toList(growable: false);
  if (ids.isEmpty) {
    return;
  }
  final count = await state.ref
      .read(taskWriteControllerProvider.notifier)
      .archiveTasks(ids);
  if (!context.mounted) {
    return;
  }
  if (!state.ref.read(taskWriteControllerProvider).hasError) {
    AppFeedback.success(
      context,
      count == 1
          ? '1 task archived to completed'
          : '$count tasks archived to completed',
      ref: state.ref,
    );
    state._clearSelectionState();
  }
}

Future<void> _deleteSelectedImpl(
  _TasksScreenState state,
  BuildContext context,
) async {
  final ids = state._selectedTaskIds.toList(growable: false);
  if (ids.isEmpty) {
    return;
  }
  final confirmed =
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => AppFormSheet(
          title: ids.length == 1
              ? 'Delete Task?'
              : 'Delete ${ids.length} Tasks?',
          subtitle: ids.length == 1
              ? 'This action cannot be undone.'
              : 'This will permanently delete ${ids.length} tasks. This cannot be undone.',
          onClose: () => Navigator.of(sheetCtx).pop(false),
          footer: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(sheetCtx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Delete',
                  variant: AppButtonVariant.danger,
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => Navigator.of(sheetCtx).pop(true),
                ),
              ),
            ],
          ),
          child: const SizedBox.shrink(),
        ),
      ) ??
      false;
  if (!confirmed) {
    return;
  }
  final count = await state.ref
      .read(taskWriteControllerProvider.notifier)
      .deleteTasks(ids);
  if (!context.mounted) {
    return;
  }
  if (!state.ref.read(taskWriteControllerProvider).hasError) {
    AppFeedback.success(
      context,
      count == 1 ? '1 task deleted' : '$count tasks deleted',
      ref: state.ref,
    );
    state._clearSelectionState();
  }
}

Future<void> _handleSuperAddFromTasksImpl(
  _TasksScreenState state,
  BuildContext context,
) async {
  final input = await showSuperAddSheet(
    context,
    defaultKind: SuperEntryKind.task,
  );
  if (input == null) {
    return;
  }
  if (input.kind == SuperEntryKind.task) {
    final priority = input.priority;
    if (priority == null) {
      if (context.mounted) {
        AppFeedback.error(
          context,
          'Choose a task priority before saving.',
          ref: state.ref,
        );
      }
      return;
    }
    await state.ref
        .read(taskWriteControllerProvider.notifier)
        .addTask(
          title: input.title,
          description: input.description,
          dueDate: input.dueAt,
          priority: switch (priority) {
            SuperEntryPriority.high => TaskPriority.high,
            SuperEntryPriority.medium => TaskPriority.medium,
            SuperEntryPriority.low => TaskPriority.low,
          },
          reminderEnabled: input.reminderEnabled,
          reminderMinutesBefore: input.reminderMinutesBefore,
        );
    if (context.mounted &&
        !state.ref.read(taskWriteControllerProvider).hasError) {
      AppFeedback.success(context, 'Task added', ref: state.ref);
    }
    return;
  }

  final eventStart = input.startAt;
  final eventType = input.eventType;
  final priority = input.priority;
  if (eventStart == null) {
    return;
  }
  if (priority == null || eventType == null) {
    if (context.mounted) {
      AppFeedback.error(
        context,
        'Choose event type and priority before saving.',
        ref: state.ref,
      );
    }
    return;
  }
  await state.ref
      .read(calendarWriteControllerProvider.notifier)
      .addEvent(
        title: input.title,
        startAt: eventStart,
        priority: switch (priority) {
          SuperEntryPriority.high => CalendarEventPriority.high,
          SuperEntryPriority.medium => CalendarEventPriority.medium,
          SuperEntryPriority.low => CalendarEventPriority.low,
        },
        type: switch (eventType) {
          SuperEntryEventType.work => CalendarEventType.work,
          SuperEntryEventType.personal => CalendarEventType.personal,
          SuperEntryEventType.finance => CalendarEventType.finance,
          SuperEntryEventType.health => CalendarEventType.health,
          SuperEntryEventType.general => CalendarEventType.general,
        },
        endAt: input.endAt,
        note: input.description,
        reminderEnabled: input.reminderEnabled,
        reminderMinutesBefore: input.reminderMinutesBefore,
      );
  if (context.mounted &&
      !state.ref.read(calendarWriteControllerProvider).hasError) {
    AppFeedback.success(context, 'Event added', ref: state.ref);
  }
}

Future<void> _editTaskWithSuperSheetImpl(
  _TasksScreenState state,
  BuildContext context,
  TaskItem task,
) async {
  final input = await showSuperAddSheet(
    context,
    defaultKind: SuperEntryKind.task,
    initialInput: SuperEntryInput(
      kind: SuperEntryKind.task,
      title: task.title,
      description: task.description,
      priority: _superPriorityFromTask(task.priority),
      dueAt: task.dueDate,
      reminderEnabled: task.reminderEnabled,
      reminderMinutesBefore: task.reminderMinutesBefore,
    ),
    actionLabel: 'Save',
    lockKind: true,
  );
  if (input == null || input.kind != SuperEntryKind.task) {
    return;
  }
  final priority = input.priority;
  if (priority == null) {
    if (context.mounted) {
      AppFeedback.error(
        context,
        'Choose a task priority before saving.',
        ref: state.ref,
      );
    }
    return;
  }
  await state.ref
      .read(taskWriteControllerProvider.notifier)
      .updateTask(
        taskId: task.id,
        title: input.title,
        description: input.description,
        dueDate: input.dueAt,
        priority: _taskPriorityFromSuper(priority),
        reminderEnabled: input.reminderEnabled,
        reminderMinutesBefore: input.reminderMinutesBefore,
      );
  if (context.mounted &&
      !state.ref.read(taskWriteControllerProvider).hasError) {
    AppFeedback.success(context, 'Task updated', ref: state.ref);
  }
}

TaskPriority _taskPriorityFromSuper(SuperEntryPriority priority) {
  return switch (priority) {
    SuperEntryPriority.high => TaskPriority.high,
    SuperEntryPriority.medium => TaskPriority.medium,
    SuperEntryPriority.low => TaskPriority.low,
  };
}

SuperEntryPriority _superPriorityFromTask(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => SuperEntryPriority.high,
    TaskPriority.medium => SuperEntryPriority.medium,
    TaskPriority.low => SuperEntryPriority.low,
  };
}
