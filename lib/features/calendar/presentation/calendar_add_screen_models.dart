import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';

enum CalendarAddTab {
  task('Task'),
  event('Event'),
  birthday('Birthday'),
  anniversary('Anniversary'),
  countdown('Countdown');

  const CalendarAddTab(this.label);
  final String label;

  CalendarEventKind toKind() => switch (this) {
        CalendarAddTab.task => CalendarEventKind.event,
        CalendarAddTab.event => CalendarEventKind.event,
        CalendarAddTab.birthday => CalendarEventKind.birthday,
        CalendarAddTab.anniversary => CalendarEventKind.anniversary,
        CalendarAddTab.countdown => CalendarEventKind.countdown,
      };
}

enum CalendarAddPage { form, repeat, reminders, timezone }

class CalendarAddTaskResult {
  const CalendarAddTaskResult({
    required this.title,
    required this.description,
    required this.priority,
    this.deadline,
    required this.reminderOffsets,
    required this.alarmEnabled,
  });

  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? deadline;
  final List<int> reminderOffsets;
  final bool alarmEnabled;
}

class CalendarAddEventResult {
  const CalendarAddEventResult({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.date,
    this.endDate,
    required this.allDay,
    required this.repeatRule,
    required this.reminderOffsets,
    required this.alarmEnabled,
    required this.guests,
    required this.timeZoneId,
    required this.kind,
    required this.reminderTimeOfDayMinutes,
  });

  final String title;
  final String description;
  final CalendarEventType type;
  final CalendarEventPriority priority;
  final DateTime date;
  final DateTime? endDate;
  final bool allDay;
  final RepeatRule repeatRule;
  final List<int> reminderOffsets;
  final bool alarmEnabled;
  final String guests;
  final String timeZoneId;
  final CalendarEventKind kind;
  final int reminderTimeOfDayMinutes;
}

class CalendarAddInitialArgs {
  const CalendarAddInitialArgs({
    this.defaultTab = CalendarAddTab.event,
    this.editingEvent,
    this.editingTask,
    this.selectedDate,
  });

  final CalendarAddTab defaultTab;
  final CalendarEvent? editingEvent;
  final TaskItem? editingTask;
  final DateTime? selectedDate;
}

class RemindersPickerResult {
  const RemindersPickerResult({
    required this.offsets,
    required this.timeOfDayMinutes,
  });

  final List<int> offsets;
  final int timeOfDayMinutes;
}
