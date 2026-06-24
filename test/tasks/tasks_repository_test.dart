import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late TasksRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = TasksRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('updateTask and deleteTask persist task changes', () async {
    await repository.addTask(
      title: 'Task CRUD',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      priority: TaskPriority.low,
      reminderEnabled: false,
      reminderMinutesBefore: 5,
    );

    final created = await repository.watchTasks().firstWhere(
      (tasks) => tasks.any((task) => task.title == 'Task CRUD'),
    );
    final task = created.firstWhere((item) => item.title == 'Task CRUD');

    await repository.updateTask(
      taskId: task.id,
      title: 'Task CRUD Updated',
      dueDate: task.dueDate,
      priority: TaskPriority.high,
      reminderEnabled: true,
      reminderMinutesBefore: 45,
    );

    final updated = await repository.watchTasks().firstWhere(
      (tasks) => tasks.any(
        (item) =>
            item.id == task.id &&
            item.title == 'Task CRUD Updated' &&
            item.priority == TaskPriority.high &&
            item.reminderEnabled &&
            item.reminderMinutesBefore == 45,
      ),
    );
    expect(updated.any((item) => item.id == task.id), isTrue);

    await repository.deleteTask(task.id);
    final afterDelete = await repository.watchTasks().firstWhere(
      (tasks) => !tasks.any((item) => item.id == task.id),
    );
    expect(afterDelete.any((item) => item.id == task.id), isFalse);
  });
}
