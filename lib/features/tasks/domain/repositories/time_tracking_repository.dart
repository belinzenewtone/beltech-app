import 'package:beltech/features/tasks/domain/entities/task_time_entry.dart';

abstract class TimeTrackingRepository {
  Future<List<TaskTimeEntry>> fetchEntries(int taskId);
  Future<TaskTimeEntry?> activeEntry(int taskId);
  Future<void> startTimer(int taskId);
  Future<void> stopTimer(int entryId);
  Future<void> deleteEntry(int entryId);
  Future<int> totalTrackedSeconds(int taskId);
}
