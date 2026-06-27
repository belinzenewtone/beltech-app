import 'package:drift/drift.dart';

class EventsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get priority => text().withDefault(const Constant('neutral'))();
  TextColumn get eventType => text().withDefault(const Constant('personal'))();
  TextColumn get eventKind => text().withDefault(const Constant('event'))();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get repeatRule => text().withDefault(const Constant('never'))();
  TextColumn get guests => text().withDefault(const Constant(''))();
  TextColumn get timeZoneId => text().withDefault(const Constant(''))();
  IntColumn get reminderTimeOfDayMinutes =>
      integer().withDefault(const Constant(480))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
