import 'package:beltech/features/tasks/domain/entities/task_item.dart';

abstract class TasksRepository {
  Stream<List<TaskItem>> watchTasks();

  Future<TaskItem> addTask({
    required String title,
    String? description,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.neutral,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
  });

  Future<void> updateTask({
    required int taskId,
    required String title,
    String? description,
    required DateTime? deadline,
    required TaskPriority priority,
    required TaskStatus status,
    DateTime? completedAt,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
  });

  Future<void> deleteTask(int taskId);
}
