import 'package:beltech/data/local/drift/app_drift_records.dart';
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
      (rows) => rows.map((row) => _toItem(row)).toList(),
    );
  }

  @override
  Future<TaskItem> addTask({
    required String title,
    String? description,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.neutral,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
  }) async {
    final id = await _store.addTask(
      title: title,
      description: description,
      deadline: deadline,
      priority: priority.name,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
    );
    return TaskItem(
      id: id,
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
    );
  }

  @override
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
  }) async {
    await _store.updateTask(
      id: taskId,
      title: title,
      description: description,
      deadline: deadline,
      priority: priority.name,
      status: status.name,
      completedAt: completedAt?.millisecondsSinceEpoch,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
    );
  }

  @override
  Future<void> deleteTask(int taskId) {
    return _store.deleteTask(taskId);
  }

  TaskItem _toItem(DriftTaskRecord row) {
    return TaskItem(
      id: row.id,
      title: row.title,
      description: row.description,
      priority: _toPriority(row.priority),
      deadline: row.deadline,
      status: _toStatus(row.status),
      completedAt: row.completedAt,
      reminderOffsets: row.reminderOffsets,
      alarmEnabled: row.alarmEnabled,
    );
  }

  TaskPriority _toPriority(String value) {
    final lower = value.toLowerCase();
    return TaskPriority.values.firstWhere(
      (p) => p.name.toLowerCase() == lower,
      orElse: () => TaskPriority.neutral,
    );
  }

  TaskStatus _toStatus(String value) {
    final lower = value.toLowerCase();
    return TaskStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == lower,
      orElse: () => TaskStatus.pending,
    );
  }
}
