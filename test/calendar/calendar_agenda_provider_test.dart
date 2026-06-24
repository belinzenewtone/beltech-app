import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('month event types prefer higher-priority type for each day', () async {
    final repository = _FakeCalendarRepository([
      CalendarEvent(
        id: 1,
        title: 'Standup',
        startAt: DateTime(2026, 4, 3, 9),
        completed: false,
        priority: CalendarEventPriority.medium,
        type: CalendarEventType.general,
      ),
      CalendarEvent(
        id: 2,
        title: 'Sprint Review',
        startAt: DateTime(2026, 4, 3, 15),
        completed: false,
        priority: CalendarEventPriority.high,
        type: CalendarEventType.work,
      ),
      CalendarEvent(
        id: 3,
        title: 'Doctor',
        startAt: DateTime(2026, 4, 9, 10),
        completed: false,
        priority: CalendarEventPriority.low,
        type: CalendarEventType.health,
      ),
      CalendarEvent(
        id: 4,
        title: 'Outside month',
        startAt: DateTime(2026, 5, 1, 10),
        completed: false,
        priority: CalendarEventPriority.low,
        type: CalendarEventType.personal,
      ),
    ]);

    final container = ProviderContainer(
      overrides: [calendarRepositoryProvider.overrideWith((ref) => repository)],
    );
    addTearDown(container.dispose);

    container.read(visibleMonthProvider.notifier).state = DateTime(2026, 4, 1);

    final dayTypes = await container.read(monthEventTypesProvider.future);

    expect(dayTypes[3], CalendarEventType.work);
    expect(dayTypes[9], CalendarEventType.health);
    expect(dayTypes.containsKey(1), isFalse);
  });
}

class _FakeCalendarRepository implements CalendarRepository {
  const _FakeCalendarRepository(this.events);

  final List<CalendarEvent> events;

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
  }) async {}

  @override
  Future<void> deleteEvent(int eventId) async {}

  @override
  Future<void> setCompleted({
    required int eventId,
    required bool completed,
  }) async {}

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
  }) async {}

  @override
  Stream<List<CalendarEvent>> watchEventsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final nextDay = dayStart.add(const Duration(days: 1));
    return Stream.value(
      events
          .where(
            (event) =>
                !event.startAt.isBefore(dayStart) &&
                event.startAt.isBefore(nextDay),
          )
          .toList(),
    );
  }

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(DateTime start, DateTime end) {
    return Stream.value(
      events
          .where(
            (event) =>
                !event.startAt.isBefore(start) && event.startAt.isBefore(end),
          )
          .toList(),
    );
  }
}
