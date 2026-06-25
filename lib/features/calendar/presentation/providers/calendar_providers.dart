import 'dart:async';

import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final visibleMonthProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final selectedDayProvider = StateProvider<DateTime>((_) => DateTime.now());

final dayEventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(calendarRepositoryProvider).watchEventsForDay(day);
});

final monthEventTypesProvider = StreamProvider<Map<int, CalendarEventType>>((
  ref,
) {
  final visibleMonth = ref.watch(visibleMonthProvider);
  final monthStart = DateTime(visibleMonth.year, visibleMonth.month, 1);
  final monthEnd = DateTime(visibleMonth.year, visibleMonth.month + 1, 1);
  return ref
      .watch(calendarRepositoryProvider)
      .watchEventsInRange(monthStart, monthEnd)
      .map((events) {
        final dayTypes = <int, CalendarEventType>{};
        for (final event in events) {
          dayTypes[event.startAt.day] = _preferType(
            dayTypes[event.startAt.day],
            event.type,
          );
        }
        return dayTypes;
      });
});

class CalendarWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addQuickEvent(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day, 14, 0);
    await addEvent(
      title: 'New Event',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      note: 'Created from Calendar tab',
    );
  }

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
    final repository = ref.read(calendarRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.addEvent(
        title: title,
        startAt: startAt,
        priority: priority,
        type: type,
        endAt: endAt,
        note: note,
        reminderEnabled: reminderEnabled,
        reminderMinutesBefore: reminderMinutesBefore,
      );
      if (reminderEnabled) {
        await _scheduleCreatedEventReminder(
          repository: repository,
          notifications: notifications,
          title: title,
          startAt: startAt,
          note: note,
          reminderMinutesBefore: reminderMinutesBefore,
        );
      }
    });
  }

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
    final repository = ref.read(calendarRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.updateEvent(
        eventId: eventId,
        title: title,
        startAt: startAt,
        priority: priority,
        type: type,
        endAt: endAt,
        note: note,
        reminderEnabled: reminderEnabled,
        reminderMinutesBefore: reminderMinutesBefore,
      );
      if (reminderEnabled) {
        await notifications.scheduleEventReminder(
          eventId: eventId,
          title: title,
          startAt: startAt,
          minutesBefore: reminderMinutesBefore,
        );
      } else {
        await notifications.cancelEventReminder(eventId);
      }
    });
  }

  Future<void> deleteEvent(int eventId) async {
    final repository = ref.read(calendarRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await notifications.cancelEventReminder(eventId);
      await repository.deleteEvent(eventId);
    });
  }

  Future<void> setEventCompleted({
    required int eventId,
    required bool completed,
  }) async {
    final repository = ref.read(calendarRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.setCompleted(eventId: eventId, completed: completed);
      if (completed) {
        await notifications.cancelEventReminder(eventId);
      }
    });
  }

  Future<void> _scheduleCreatedEventReminder({
    required CalendarRepository repository,
    required LocalNotificationService notifications,
    required String title,
    required DateTime startAt,
    String? note,
    required int reminderMinutesBefore,
  }) async {
    try {
      final dayStart = DateTime(startAt.year, startAt.month, startAt.day);
      final events = await repository.watchEventsForDay(dayStart).first;
      final created = events.where((event) {
        final sameNote = (event.note ?? '') == (note ?? '');
        return event.title == title &&
            event.startAt.isAtSameMomentAs(startAt) &&
            sameNote;
      }).firstOrNull;
      if (created == null) {
        return;
      }
      await notifications.scheduleEventReminder(
        eventId: created.id,
        title: created.title,
        startAt: created.startAt,
        minutesBefore: reminderMinutesBefore,
      );
    } catch (_) {
      return;
    }
  }
}

final calendarWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<CalendarWriteController, void>(
      CalendarWriteController.new,
    );

CalendarEventType _preferType(
  CalendarEventType? current,
  CalendarEventType incoming,
) {
  if (current == null) {
    return incoming;
  }
  const weight = <CalendarEventType, int>{
    CalendarEventType.work: 5,
    CalendarEventType.finance: 4,
    CalendarEventType.health: 3,
    CalendarEventType.personal: 2,
    CalendarEventType.general: 1,
  };
  return (weight[incoming] ?? 0) >= (weight[current] ?? 0) ? incoming : current;
}

enum CalendarViewMode { month, week, day }

final calendarViewModeProvider = StateProvider<CalendarViewMode>(
  (_) => CalendarViewMode.month,
);

final visibleWeekStartProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
});

final weekEventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  final weekStart = ref.watch(visibleWeekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 7));
  return ref
      .watch(calendarRepositoryProvider)
      .watchEventsInRange(weekStart, weekEnd);
});
