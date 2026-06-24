import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reminder_integration_fakes.dart';

void main() {
  test('task add/update triggers schedule and cancel hooks', () async {
    final tasksRepo = FakeTasksRepository();
    final notifications = FakeLocalNotificationService();
    final container = ProviderContainer(
      overrides: [
        tasksRepositoryProvider.overrideWithValue(tasksRepo),
        localNotificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    final due = DateTime.now().add(const Duration(days: 1));
    await container
        .read(taskWriteControllerProvider.notifier)
        .addTask(
          title: 'Reminder Task',
          dueDate: due,
          priority: TaskPriority.high,
          reminderMinutesBefore: 45,
        );

    expect(notifications.scheduledTaskIds, contains(1));
    expect(notifications.scheduledTaskReminderMinutes, contains(45));

    await container
        .read(taskWriteControllerProvider.notifier)
        .updateTask(
          taskId: 1,
          title: 'Reminder Task',
          dueDate: null,
          priority: TaskPriority.high,
          reminderMinutesBefore: 45,
        );

    expect(notifications.canceledTaskIds, contains(1));
  });

  test('task add/update skips scheduling when reminder is disabled', () async {
    final tasksRepo = FakeTasksRepository();
    final notifications = FakeLocalNotificationService();
    final container = ProviderContainer(
      overrides: [
        tasksRepositoryProvider.overrideWithValue(tasksRepo),
        localNotificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    final due = DateTime.now().add(const Duration(days: 2));
    await container
        .read(taskWriteControllerProvider.notifier)
        .addTask(
          title: 'No Reminder Task',
          dueDate: due,
          priority: TaskPriority.low,
          reminderEnabled: false,
          reminderMinutesBefore: 10,
        );

    expect(notifications.scheduledTaskIds, isEmpty);

    await container
        .read(taskWriteControllerProvider.notifier)
        .updateTask(
          taskId: 1,
          title: 'No Reminder Task',
          dueDate: due,
          priority: TaskPriority.low,
          reminderEnabled: false,
          reminderMinutesBefore: 10,
        );

    expect(notifications.scheduledTaskIds, isEmpty);
    expect(notifications.canceledTaskIds, contains(1));
  });

  test('event add/delete triggers schedule and cancel hooks', () async {
    final calendarRepo = FakeCalendarRepository();
    final notifications = FakeLocalNotificationService();
    final container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWithValue(calendarRepo),
        localNotificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    final day = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(day.year, day.month, day.day, 11);
    await container
        .read(calendarWriteControllerProvider.notifier)
        .addEvent(
          title: 'Team Call',
          startAt: start,
          priority: CalendarEventPriority.medium,
          type: CalendarEventType.work,
          endAt: start.add(const Duration(hours: 1)),
          note: 'Planning',
          reminderMinutesBefore: 20,
        );

    expect(notifications.scheduledEventIds, contains(1));
    expect(notifications.scheduledEventReminderMinutes, contains(20));

    await container
        .read(calendarWriteControllerProvider.notifier)
        .deleteEvent(1);
    expect(notifications.canceledEventIds, contains(1));
  });

  test('event add/update skips scheduling when reminder is disabled', () async {
    final calendarRepo = FakeCalendarRepository();
    final notifications = FakeLocalNotificationService();
    final container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWithValue(calendarRepo),
        localNotificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);

    final day = DateTime.now().add(const Duration(days: 3));
    final start = DateTime(day.year, day.month, day.day, 9, 30);
    await container
        .read(calendarWriteControllerProvider.notifier)
        .addEvent(
          title: 'No Reminder Event',
          startAt: start,
          priority: CalendarEventPriority.low,
          type: CalendarEventType.personal,
          reminderEnabled: false,
          reminderMinutesBefore: 5,
        );

    expect(notifications.scheduledEventIds, isEmpty);

    await container
        .read(calendarWriteControllerProvider.notifier)
        .updateEvent(
          eventId: 1,
          title: 'No Reminder Event',
          startAt: start,
          priority: CalendarEventPriority.low,
          type: CalendarEventType.personal,
          reminderEnabled: false,
          reminderMinutesBefore: 5,
        );

    expect(notifications.scheduledEventIds, isEmpty);
    expect(notifications.canceledEventIds, contains(1));
  });
}
