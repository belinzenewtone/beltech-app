import 'package:beltech/features/tasks/domain/entities/task_item.dart';

abstract class TasksRepository {
  Stream<List<TaskItem>> watchTasks();

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  });

  Future<void> toggleCompleted({required int taskId, required bool completed});

  Future<void> updateTask({
    required int taskId,
    required String title,
    String? description,
    required DateTime? dueDate,
    required TaskPriority priority,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  });

  Future<void> deleteTask(int taskId);
}
