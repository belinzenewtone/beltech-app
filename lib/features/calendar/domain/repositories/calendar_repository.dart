import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day);
  Stream<List<CalendarEvent>> watchEventsInRange(DateTime start, DateTime end);
  Stream<List<CalendarEvent>> watchAllEvents();

  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    CalendarEventPriority priority = CalendarEventPriority.medium,
    CalendarEventType type = CalendarEventType.general,
    DateTime? endAt,
    String? note,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 15,
  });

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
  });

  Future<void> setCompleted({required int eventId, required bool completed});

  Future<void> deleteEvent(int eventId);
}
