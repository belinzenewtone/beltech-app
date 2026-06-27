import 'dart:async';
import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/domain/repositories/tasks_repository.dart';

class FakeLocalNotificationService extends LocalNotificationService {
  final List<int> scheduledTaskIds = [];
  final List<int> canceledTaskIds = [];
  final List<int> scheduledEventIds = [];
  final List<int> canceledEventIds = [];
  final List<int> scheduledTaskReminderMinutes = [];
  final List<int> scheduledEventReminderMinutes = [];

  @override
  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required DateTime deadline,
    List<int> reminderOffsets = const [30],
    bool alarmEnabled = false,
  }) async {
    if (reminderOffsets.isEmpty) return;
    scheduledTaskIds.add(taskId);
    scheduledTaskReminderMinutes.addAll(reminderOffsets);
  }

  @override
  Future<void> cancelTaskReminder(int taskId) async {
    canceledTaskIds.add(taskId);
  }

  @override
  Future<void> scheduleEventReminder({
    required int eventId,
    required String title,
    required DateTime startAt,
    List<int> reminderOffsets = const [15],
    bool alarmEnabled = false,
    CalendarEventKind kind = CalendarEventKind.event,
    bool allDay = false,
    int reminderTimeOfDayMinutes = 480,
  }) async {
    if (reminderOffsets.isEmpty) return;
    scheduledEventIds.add(eventId);
    scheduledEventReminderMinutes.addAll(reminderOffsets);
  }

  @override
  Future<void> cancelEventReminder(int eventId) async {
    canceledEventIds.add(eventId);
  }
}

class FakeTasksRepository implements TasksRepository {
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final List<TaskItem> _tasks = [];
  int _nextId = 1;

  @override
  Stream<List<TaskItem>> watchTasks() {
    return Stream<List<TaskItem>>.multi((controller) {
      controller.add(List.unmodifiable(_tasks));
      final sub = _changes.stream.listen((_) {
        controller.add(List.unmodifiable(_tasks));
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<TaskItem> addTask({
    required String title,
    String? description,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.neutral,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
  }) async {
    final created = TaskItem(
      id: _nextId++,
      title: title,
      description: description,
      status: TaskStatus.pending,
      priority: priority,
      deadline: deadline,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
    );
    _tasks.insert(0, created);
    _changes.add(null);
    return created;
  }

  @override
  Future<void> updateTask({
    required int taskId,
    required String title,
    String? description,
    required DateTime? deadline,
    required TaskPriority priority,
    required TaskStatus status,
    DateTime? completedAt,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
  }) async {
    final index = _tasks.indexWhere((item) => item.id == taskId);
    if (index == -1) {
      return;
    }
    _tasks[index] = TaskItem(
      id: taskId,
      title: title,
      description: description,
      status: status,
      completedAt: completedAt,
      priority: priority,
      deadline: deadline,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
    );
    _changes.add(null);
  }

  @override
  Future<void> deleteTask(int taskId) async {
    _tasks.removeWhere((item) => item.id == taskId);
    _changes.add(null);
  }
}

class FakeCalendarRepository implements CalendarRepository {
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final List<CalendarEvent> _events = [];
  int _nextId = 1;

  @override
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day) {
    return Stream<List<CalendarEvent>>.multi((controller) {
      controller.add(_eventsFor(day));
      final sub = _changes.stream.listen((_) {
        controller.add(_eventsFor(day));
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(DateTime start, DateTime end) {
    return Stream<List<CalendarEvent>>.multi((controller) {
      controller.add(_eventsInRange(start, end));
      final sub = _changes.stream.listen((_) {
        controller.add(_eventsInRange(start, end));
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<CalendarEvent>> watchAllEvents() {
    return Stream<List<CalendarEvent>>.multi((controller) {
      controller.add(List.unmodifiable(_events));
      final sub = _changes.stream.listen((_) {
        controller.add(List.unmodifiable(_events));
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    CalendarEventPriority priority = CalendarEventPriority.neutral,
    CalendarEventType type = CalendarEventType.personal,
    CalendarEventKind kind = CalendarEventKind.event,
    DateTime? endAt,
    String? note,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
    bool allDay = false,
    RepeatRule repeatRule = RepeatRule.never,
    String guests = '',
    String timeZoneId = '',
    int reminderTimeOfDayMinutes = 480,
  }) async {
    _events.add(
      CalendarEvent(
        id: _nextId++,
        title: title,
        startAt: startAt,
        completed: false,
        priority: priority,
        kind: kind,
        type: type,
        endAt: endAt,
        note: note,
        reminderOffsets: reminderOffsets,
        alarmEnabled: alarmEnabled,
        allDay: allDay,
        repeatRule: repeatRule,
        guests: guests,
        timeZoneId: timeZoneId,
        reminderTimeOfDayMinutes: reminderTimeOfDayMinutes,
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> updateEvent({
    required int eventId,
    required String title,
    required DateTime startAt,
    required CalendarEventPriority priority,
    required CalendarEventType type,
    required CalendarEventKind kind,
    DateTime? endAt,
    String? note,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
    bool allDay = false,
    RepeatRule repeatRule = RepeatRule.never,
    String guests = '',
    String timeZoneId = '',
    int reminderTimeOfDayMinutes = 480,
  }) async {
    final index = _events.indexWhere((item) => item.id == eventId);
    if (index == -1) {
      return;
    }
    _events[index] = CalendarEvent(
      id: eventId,
      title: title,
      startAt: startAt,
      completed: _events[index].completed,
      priority: priority,
      kind: kind,
      type: type,
      endAt: endAt,
      note: note,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
      allDay: allDay,
      repeatRule: repeatRule,
      guests: guests,
      timeZoneId: timeZoneId,
      reminderTimeOfDayMinutes: reminderTimeOfDayMinutes,
    );
    _changes.add(null);
  }

  @override
  Future<void> setCompleted({
    required int eventId,
    required bool completed,
  }) async {
    final index = _events.indexWhere((item) => item.id == eventId);
    if (index == -1) {
      return;
    }
    final current = _events[index];
    _events[index] = CalendarEvent(
      id: current.id,
      title: current.title,
      startAt: current.startAt,
      completed: completed,
      priority: current.priority,
      type: current.type,
      endAt: current.endAt,
      note: current.note,
      reminderOffsets: current.reminderOffsets,
      alarmEnabled: current.alarmEnabled,
    );
    _changes.add(null);
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    _events.removeWhere((item) => item.id == eventId);
    _changes.add(null);
  }

  List<CalendarEvent> _eventsFor(DateTime day) {
    return _events.where((event) {
      return event.startAt.year == day.year &&
          event.startAt.month == day.month &&
          event.startAt.day == day.day;
    }).toList();
  }

  List<CalendarEvent> _eventsInRange(DateTime start, DateTime end) {
    return _events.where((event) {
      return !event.startAt.isBefore(start) && event.startAt.isBefore(end);
    }).toList();
  }
}
