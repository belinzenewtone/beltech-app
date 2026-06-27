import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day);
  Stream<List<CalendarEvent>> watchEventsInRange(DateTime start, DateTime end);
  Stream<List<CalendarEvent>> watchAllEvents();

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
  });

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
  });

  Future<void> setCompleted({required int eventId, required bool completed});

  Future<void> deleteEvent(int eventId);
}
