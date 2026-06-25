part of 'calendar_screen.dart';

Future<void> _handleSuperAddFromCalendarImpl(
  _CalendarScreenState state,
  BuildContext context,
  DateTime selectedDay, {
  SuperEntryKind defaultKind = SuperEntryKind.event,
}) async {
  final input = await showSuperAddSheet(
    context,
    defaultKind: defaultKind,
    contextDate: selectedDay,
  );
  if (input == null) {
    return;
  }

  // ── Task ──
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

  // ── Event-like entries (event, birthday, anniversary, countdown) ──
  final eventStart = input.startAt;
  if (eventStart == null) {
    return;
  }

  final CalendarEventType type;
  final CalendarEventPriority priority;

  switch (input.kind) {
    case SuperEntryKind.event:
      if (input.priority == null || input.eventType == null) {
        if (context.mounted) {
          AppFeedback.error(
            context,
            'Choose event type and priority before saving.',
            ref: state.ref,
          );
        }
        return;
      }
      type = _eventTypeFromSuper(input.eventType!);
      priority = _eventPriorityFromSuper(input.priority!);
    case SuperEntryKind.birthday:
      type = CalendarEventType.birthday;
      priority = CalendarEventPriority.medium;
    case SuperEntryKind.anniversary:
      type = CalendarEventType.anniversary;
      priority = CalendarEventPriority.medium;
    case SuperEntryKind.countdown:
      type = CalendarEventType.countdown;
      priority = CalendarEventPriority.high;
    default:
      return;
  }

  String? note = input.description;
  if (input.kind == SuperEntryKind.birthday && input.year != null) {
    note = '${note ?? ''}\nBorn in ${input.year}';
  }

  await state.ref
      .read(calendarWriteControllerProvider.notifier)
      .addEvent(
        title: input.title,
        startAt: eventStart,
        priority: priority,
        type: type,
        endAt: input.endAt,
        note: note?.trim(),
        reminderEnabled: input.reminderEnabled,
        reminderMinutesBefore: input.reminderMinutesBefore,
      );
  if (context.mounted &&
      !state.ref.read(calendarWriteControllerProvider).hasError) {
    final label = switch (input.kind) {
      SuperEntryKind.event => 'Event',
      SuperEntryKind.birthday => 'Birthday',
      SuperEntryKind.anniversary => 'Anniversary',
      SuperEntryKind.countdown => 'Countdown',
      _ => 'Entry',
    };
    AppFeedback.success(context, '$label added', ref: state.ref);
  }
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

Future<void> _editEventWithSuperSheetImpl(
  _CalendarScreenState state,
  BuildContext context,
  CalendarEvent event,
  DateTime selectedDay,
) async {
  final input = await showSuperAddSheet(
    context,
    defaultKind: SuperEntryKind.event,
    contextDate: selectedDay,
    initialInput: SuperEntryInput(
      kind: SuperEntryKind.event,
      title: event.title,
      description: event.note,
      priority: _superPriorityFromEvent(event.priority),
      startAt: event.startAt,
      endAt: event.endAt,
      eventType: _superTypeFromEvent(event.type),
      reminderEnabled: event.reminderEnabled,
      reminderMinutesBefore: event.reminderMinutesBefore,
    ),
    actionLabel: 'Save',
    lockKind: true,
  );
  if (input == null || input.kind != SuperEntryKind.event) {
    return;
  }
  final eventStart = input.startAt;
  final priority = input.priority;
  final eventType = input.eventType;
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
      .updateEvent(
        eventId: event.id,
        title: input.title,
        startAt: eventStart,
        priority: _eventPriorityFromSuper(priority),
        type: _eventTypeFromSuper(eventType),
        endAt: input.endAt,
        note: input.description,
        reminderEnabled: input.reminderEnabled,
        reminderMinutesBefore: input.reminderMinutesBefore,
      );
  if (context.mounted &&
      !state.ref.read(calendarWriteControllerProvider).hasError) {
    AppFeedback.success(context, 'Event updated', ref: state.ref);
  }
}

CalendarEventPriority _eventPriorityFromSuper(SuperEntryPriority priority) {
  return switch (priority) {
    SuperEntryPriority.high => CalendarEventPriority.high,
    SuperEntryPriority.medium => CalendarEventPriority.medium,
    SuperEntryPriority.low => CalendarEventPriority.low,
  };
}

SuperEntryPriority _superPriorityFromEvent(CalendarEventPriority priority) {
  return switch (priority) {
    CalendarEventPriority.high => SuperEntryPriority.high,
    CalendarEventPriority.medium => SuperEntryPriority.medium,
    CalendarEventPriority.low => SuperEntryPriority.low,
  };
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

CalendarEventType _eventTypeFromSuper(SuperEntryEventType type) {
  return switch (type) {
    SuperEntryEventType.work => CalendarEventType.work,
    SuperEntryEventType.personal => CalendarEventType.personal,
    SuperEntryEventType.finance => CalendarEventType.finance,
    SuperEntryEventType.health => CalendarEventType.health,
    SuperEntryEventType.general => CalendarEventType.general,
  };
}

SuperEntryEventType _superTypeFromEvent(CalendarEventType type) {
  return switch (type) {
    CalendarEventType.work => SuperEntryEventType.work,
    CalendarEventType.personal => SuperEntryEventType.personal,
    CalendarEventType.finance => SuperEntryEventType.finance,
    CalendarEventType.health => SuperEntryEventType.health,
    CalendarEventType.general ||
    CalendarEventType.birthday ||
    CalendarEventType.anniversary ||
    CalendarEventType.countdown => SuperEntryEventType.general,
  };
}
