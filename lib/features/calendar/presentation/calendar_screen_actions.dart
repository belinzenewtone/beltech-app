part of 'calendar_screen.dart';

Future<void> _openCalendarAddScreen(
  _CalendarScreenState state,
  BuildContext context, {
  required CalendarAddTab tab,
  DateTime? selectedDate,
  CalendarEvent? editingEvent,
}) async {
  final args = CalendarAddInitialArgs(
    defaultTab: tab,
    selectedDate: selectedDate,
    editingEvent: editingEvent,
  );
  if (!context.mounted) return;
  final result = await context.push<bool>('/calendar-add', extra: args);
  if (result == true && context.mounted) {
    AppFeedback.success(context, editingEvent != null ? 'Updated' : 'Added', ref: state.ref);
  }
}

Future<void> _handleSuperAddFromCalendarImpl(
  _CalendarScreenState state,
  BuildContext context,
  DateTime selectedDay, {
  SuperEntryKind defaultKind = SuperEntryKind.event,
}) async {
  // Tasks still use the compact SuperAddSheet because they are persisted in the
  // tasks domain, not the calendar-events domain.
  if (defaultKind == SuperEntryKind.task) {
    final input = await showSuperAddSheet(
      context,
      defaultKind: SuperEntryKind.task,
      contextDate: selectedDay,
    );
    if (input == null) return;

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

  final tab = _calendarAddTabFromSuperKind(defaultKind);
  await _openCalendarAddScreen(
    state,
    context,
    tab: tab,
    selectedDate: selectedDay,
  );
}

Future<void> _editTaskWithSuperSheetImpl(
  _CalendarScreenState state,
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

Future<void> _editEventWithSuperSheetImpl(
  _CalendarScreenState state,
  BuildContext context,
  CalendarEvent event,
  DateTime selectedDay,
) async {
  final tab = _calendarAddTabFromEventKind(event.kind);
  await _openCalendarAddScreen(
    state,
    context,
    tab: tab,
    selectedDate: selectedDay,
    editingEvent: event,
  );
}

CalendarAddTab _calendarAddTabFromSuperKind(SuperEntryKind kind) {
  return switch (kind) {
    SuperEntryKind.task => CalendarAddTab.task,
    SuperEntryKind.event => CalendarAddTab.event,
    SuperEntryKind.birthday => CalendarAddTab.birthday,
    SuperEntryKind.anniversary => CalendarAddTab.anniversary,
    SuperEntryKind.countdown => CalendarAddTab.countdown,
  };
}

CalendarAddTab _calendarAddTabFromEventKind(CalendarEventKind kind) {
  return switch (kind) {
    CalendarEventKind.event => CalendarAddTab.event,
    CalendarEventKind.birthday => CalendarAddTab.birthday,
    CalendarEventKind.anniversary => CalendarAddTab.anniversary,
    CalendarEventKind.countdown => CalendarAddTab.countdown,
  };
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
