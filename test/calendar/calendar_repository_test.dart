import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late CalendarRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = CalendarRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('updateEvent and deleteEvent persist event changes', () async {
    final day = DateTime.now();
    final startAt = DateTime(day.year, day.month, day.day, 10, 0);
    await repository.addEvent(
      title: 'Calendar CRUD',
      startAt: startAt,
      endAt: startAt.add(const Duration(hours: 1)),
      note: 'before update',
      reminderEnabled: false,
      reminderMinutesBefore: 5,
    );

    final created = await repository
        .watchEventsForDay(day)
        .firstWhere(
          (events) => events.any((event) => event.title == 'Calendar CRUD'),
        );
    final event = created.firstWhere((item) => item.title == 'Calendar CRUD');

    await repository.updateEvent(
      eventId: event.id,
      title: 'Calendar CRUD Updated',
      startAt: event.startAt,
      priority: event.priority,
      type: event.type,
      endAt: event.endAt,
      note: 'after update',
      reminderEnabled: true,
      reminderMinutesBefore: 60,
    );

    final updated = await repository
        .watchEventsForDay(day)
        .firstWhere(
          (events) => events.any(
            (item) =>
                item.id == event.id &&
                item.title == 'Calendar CRUD Updated' &&
                item.reminderEnabled &&
                item.reminderMinutesBefore == 60,
          ),
        );
    expect(updated.any((item) => item.id == event.id), isTrue);

    await repository.deleteEvent(event.id);
    final afterDelete = await repository
        .watchEventsForDay(day)
        .firstWhere((events) => !events.any((item) => item.id == event.id));
    expect(afterDelete.any((item) => item.id == event.id), isFalse);
  });
}
