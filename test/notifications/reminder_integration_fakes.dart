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
    required DateTime dueDate,
    int minutesBefore = 30,
  }) async {
    scheduledTaskIds.add(taskId);
    scheduledTaskReminderMinutes.add(minutesBefore);
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
    int minutesBefore = 15,
  }) async {
    scheduledEventIds.add(eventId);
    scheduledEventReminderMinutes.add(minutesBefore);
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
  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  }) async {
    _tasks.insert(
      0,
      TaskItem(
        id: _nextId++,
        title: title,
        description: description,
        completed: false,
        priority: priority,
        dueDate: dueDate,
        reminderEnabled: reminderEnabled,
        reminderMinutesBefore: reminderMinutesBefore,
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> toggleCompleted({
    required int taskId,
    required bool completed,
  }) async {
    final index = _tasks.indexWhere((item) => item.id == taskId);
    if (index == -1) {
      return;
    }
    final current = _tasks[index];
    _tasks[index] = TaskItem(
      id: current.id,
      title: current.title,
      description: current.description,
      completed: completed,
      priority: current.priority,
      dueDate: current.dueDate,
    );
    _changes.add(null);
  }

  @override
  Future<void> updateTask({
    required int taskId,
    required String title,
    String? description,
    required DateTime? dueDate,
    required TaskPriority priority,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  }) async {
    final index = _tasks.indexWhere((item) => item.id == taskId);
    if (index == -1) {
      return;
    }
    final current = _tasks[index];
    _tasks[index] = TaskItem(
      id: taskId,
      title: title,
      description: description ?? current.description,
      completed: current.completed,
      priority: priority,
      dueDate: dueDate,
      reminderEnabled: reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore,
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
    CalendarEventPriority priority = CalendarEventPriority.medium,
    CalendarEventType type = CalendarEventType.general,
    DateTime? endAt,
    String? note,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 15,
  }) async {
    _events.add(
      CalendarEvent(
        id: _nextId++,
        title: title,
        startAt: startAt,
        completed: false,
        priority: priority,
        type: type,
        endAt: endAt,
        note: note,
        reminderEnabled: reminderEnabled,
        reminderMinutesBefore: reminderMinutesBefore,
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
    DateTime? endAt,
    String? note,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 15,
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
      type: type,
      endAt: endAt,
      note: note,
      reminderEnabled: reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore,
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
      reminderEnabled: current.reminderEnabled,
      reminderMinutesBefore: current.reminderMinutesBefore,
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
