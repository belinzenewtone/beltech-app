import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/app_drift_store_mutations.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day) {
    return _store.watchEventsForDay(day).map((rows) => rows.map(_toEvent).toList());
  }

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(DateTime start, DateTime end) {
    return _store
        .watchEventsInRange(start, end)
        .map((rows) => rows.map(_toEvent).toList());
  }

  @override
  Stream<List<CalendarEvent>> watchAllEvents() {
    return _store.watchAllEvents().map((rows) => rows.map(_toEvent).toList());
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
    await _store.addEvent(
      title: title,
      startAt: startAt,
      priority: calendarEventPriorityToRaw(priority),
      eventType: calendarEventTypeToRaw(type),
      eventKind: calendarEventKindToRaw(kind),
      endAt: endAt,
      note: note,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
      allDay: allDay,
      repeatRule: repeatRuleToRaw(repeatRule),
      guests: guests,
      timeZoneId: timeZoneId,
      reminderTimeOfDayMinutes: reminderTimeOfDayMinutes,
    );
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
  }) {
    return _store.updateEvent(
      id: eventId,
      title: title,
      startAt: startAt,
      priority: calendarEventPriorityToRaw(priority),
      eventType: calendarEventTypeToRaw(type),
      eventKind: calendarEventKindToRaw(kind),
      endAt: endAt,
      note: note,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
      allDay: allDay,
      repeatRule: repeatRuleToRaw(repeatRule),
      guests: guests,
      timeZoneId: timeZoneId,
      reminderTimeOfDayMinutes: reminderTimeOfDayMinutes,
    );
  }

  @override
  Future<void> setCompleted({required int eventId, required bool completed}) {
    return _store.setEventCompletion(eventId: eventId, completed: completed);
  }

  @override
  Future<void> deleteEvent(int eventId) {
    return _store.deleteEvent(eventId);
  }

  CalendarEvent _toEvent(dynamic row) {
    return CalendarEvent(
      id: row.id,
      title: row.title,
      startAt: row.startAt,
      completed: row.completed,
      priority: calendarEventPriorityFromRaw(row.priority),
      kind: calendarEventKindFromRaw(row.eventKind),
      type: calendarEventTypeFromRaw(row.eventType),
      endAt: row.endAt,
      note: row.note,
      reminderOffsets: row.reminderOffsets,
      alarmEnabled: row.alarmEnabled,
      allDay: row.allDay,
      repeatRule: repeatRuleFromRaw(row.repeatRule),
      guests: row.guests,
      timeZoneId: row.timeZoneId,
      reminderTimeOfDayMinutes: row.reminderTimeOfDayMinutes,
    );
  }
}
