import 'package:drift/drift.dart';

class EventsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get eventType => text().withDefault(const Constant('general'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
