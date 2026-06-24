import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/app_drift_store_mutations.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/domain/repositories/tasks_repository.dart';

class TasksRepositoryImpl implements TasksRepository {
  TasksRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<TaskItem>> watchTasks() {
    return _store.watchTasks().map(
      (rows) => rows
          .map(
            (row) => TaskItem(
              id: row.id,
              title: row.title,
              description: row.description,
              completed: row.completed,
              priority: _toPriority(row.priority),
              dueDate: row.dueDate,
              reminderEnabled: row.reminderEnabled,
              reminderMinutesBefore: row.reminderMinutesBefore,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  }) async {
    await _store.addTask(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority.name,
      reminderEnabled: reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore,
    );
  }

  @override
  Future<void> toggleCompleted({
    required int taskId,
    required bool completed,
  }) async {
    await _store.toggleTaskCompletion(taskId: taskId, completed: completed);
  }

  @override
  Future<void> updateTask({
    required int taskId,
    required String title,
    String? description,
    required DateTime? dueDate,
    required TaskPriority priority,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  }) async {
    await _store.updateTask(
      id: taskId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority.name,
      reminderEnabled: reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore,
    );
  }

  @override
  Future<void> deleteTask(int taskId) {
    return _store.deleteTask(taskId);
  }

  TaskPriority _toPriority(String value) {
    return switch (value.toLowerCase()) {
      'high' => TaskPriority.high,
      'low' => TaskPriority.low,
      _ => TaskPriority.medium,
    };
  }
}
