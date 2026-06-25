import 'package:drift/drift.dart';

class TasksTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
