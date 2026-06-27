part of 'tasks_screen.dart';

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
    await state.ref.read(taskWriteControllerProvider.notifier).addTask(
      title: input.title,
      description: input.description,
      deadline: input.dueAt,
      priority: _taskPriorityFromSuper(priority),
      reminderOffsets: input.reminderOffsets ?? const [],
      alarmEnabled: input.alarmEnabled,
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
  await state.ref.read(calendarWriteControllerProvider.notifier).addEvent(
    title: input.title,
    startAt: eventStart,
    priority: switch (priority) {
      SuperEntryPriority.high => CalendarEventPriority.urgent,
      SuperEntryPriority.medium => CalendarEventPriority.important,
      SuperEntryPriority.low => CalendarEventPriority.neutral,
    },
    type: switch (eventType) {
      SuperEntryEventType.work => CalendarEventType.work,
      SuperEntryEventType.personal => CalendarEventType.personal,
      SuperEntryEventType.finance => CalendarEventType.finance,
      SuperEntryEventType.health => CalendarEventType.health,
      SuperEntryEventType.general => CalendarEventType.other,
    },
    endAt: input.endAt,
    note: input.description,
    reminderOffsets: input.reminderOffsets ?? const [],
    alarmEnabled: input.alarmEnabled,
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
      dueAt: task.deadline,
      reminderOffsets: task.reminderOffsets,
      alarmEnabled: task.alarmEnabled,
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
  await state.ref.read(taskWriteControllerProvider.notifier).updateTask(
    taskId: task.id,
    title: input.title,
    description: input.description,
    deadline: input.dueAt,
    priority: _taskPriorityFromSuper(priority),
    reminderOffsets: input.reminderOffsets ?? const [],
    alarmEnabled: input.alarmEnabled,
  );
  if (context.mounted &&
      !state.ref.read(taskWriteControllerProvider).hasError) {
    AppFeedback.success(context, 'Task updated', ref: state.ref);
  }
}

TaskPriority _taskPriorityFromSuper(SuperEntryPriority priority) {
  return switch (priority) {
    SuperEntryPriority.high => TaskPriority.urgent,
    SuperEntryPriority.medium => TaskPriority.important,
    SuperEntryPriority.low => TaskPriority.neutral,
  };
}

SuperEntryPriority _superPriorityFromTask(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.urgent => SuperEntryPriority.high,
    TaskPriority.important => SuperEntryPriority.medium,
    TaskPriority.neutral => SuperEntryPriority.low,
  };
}
