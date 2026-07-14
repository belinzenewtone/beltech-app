import 'dart:async';

import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum TaskFilter { all, pending, completed }

final taskFilterProvider = StateProvider<TaskFilter>((_) => TaskFilter.all);

final tasksProvider = StreamProvider<List<TaskItem>>(
  (ref) => ref.watch(tasksRepositoryProvider).watchTasks(),
);

final filteredTasksProvider = Provider<AsyncValue<List<TaskItem>>>((ref) {
  final tasksState = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);
  return tasksState.whenData((tasks) {
    return switch (filter) {
      TaskFilter.pending => tasks.where((task) => !task.completed).toList(),
      TaskFilter.completed => tasks.where((task) => task.completed).toList(),
      TaskFilter.all => tasks,
    };
  });
});

class TaskWriteController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addQuickTask() async {
    final now = DateTime.now();
    await addTask(
      title: 'New Task ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      deadline: now.add(const Duration(days: 1)),
      priority: TaskPriority.neutral,
    );
  }

  Future<TaskItem?> addTask({
    required String title,
    String? description,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.neutral,
    List<int> reminderOffsets = const [],
    bool alarmEnabled = false,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    state = const AsyncLoading();
    TaskItem? created;
    state = await AsyncValue.guard(() async {
      created = await repository.addTask(
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        reminderOffsets: reminderOffsets,
        alarmEnabled: alarmEnabled,
      );
      if (created != null &&
          deadline != null &&
          !created!.completed &&
          reminderOffsets.isNotEmpty) {
        await _scheduleTaskReminders(
          taskId: created!.id,
          title: created!.title,
          deadline: deadline,
          reminderOffsets: reminderOffsets,
          alarmEnabled: alarmEnabled,
        );
      }
    });
    return created;
  }

  Future<void> toggleTask({
    required int taskId,
    required bool completed,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    final tasks = await repository.watchTasks().first;
    final taskBeforeChange = tasks.where((item) => item.id == taskId).firstOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (taskBeforeChange == null) return;
      await repository.updateTask(
        taskId: taskId,
        title: taskBeforeChange.title,
        description: taskBeforeChange.description,
        deadline: taskBeforeChange.deadline,
        priority: taskBeforeChange.priority,
        status: completed ? TaskStatus.completed : TaskStatus.pending,
        completedAt: completed ? DateTime.now() : null,
        reminderOffsets: taskBeforeChange.reminderOffsets,
        alarmEnabled: taskBeforeChange.alarmEnabled,
      );
      if (completed) {
        await _cancelTaskReminders(taskId);
      } else if (taskBeforeChange.deadline != null &&
          taskBeforeChange.reminderOffsets.isNotEmpty) {
        await _scheduleTaskReminders(
          taskId: taskId,
          title: taskBeforeChange.title,
          deadline: taskBeforeChange.deadline!,
          reminderOffsets: taskBeforeChange.reminderOffsets,
          alarmEnabled: taskBeforeChange.alarmEnabled,
        );
      }
    });
  }

  Future<void> updateTask({
    required int taskId,
    required String title,
    String? description,
    required DateTime? deadline,
    required TaskPriority priority,
    required List<int> reminderOffsets,
    required bool alarmEnabled,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        status: TaskStatus.pending,
        reminderOffsets: reminderOffsets,
        alarmEnabled: alarmEnabled,
      );
      if (deadline == null || reminderOffsets.isEmpty) {
        await _cancelTaskReminders(taskId);
      } else {
        await _scheduleTaskReminders(
          taskId: taskId,
          title: title,
          deadline: deadline,
          reminderOffsets: reminderOffsets,
          alarmEnabled: alarmEnabled,
        );
      }
    });
  }

  Future<void> _scheduleTaskReminders({
    required int taskId,
    required String title,
    required DateTime deadline,
    required List<int> reminderOffsets,
    required bool alarmEnabled,
  }) async {
    final notifications = ref.read(localNotificationServiceProvider);
    await notifications.scheduleTaskReminder(
      taskId: taskId,
      title: title,
      deadline: deadline,
      reminderOffsets: reminderOffsets,
      alarmEnabled: alarmEnabled,
    );
  }

  Future<void> _cancelTaskReminders(int taskId) async {
    final notifications = ref.read(localNotificationServiceProvider);
    await notifications.cancelTaskReminder(taskId);
  }

  Future<void> deleteTask(int taskId) async {
    final repository = ref.read(tasksRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _cancelTaskReminders(taskId);
      await repository.deleteTask(taskId);
    });
  }

  Future<int> completeTasks(Iterable<int> taskIds) async {
    final ids = taskIds.toSet();
    if (ids.isEmpty) {
      return 0;
    }

    final repository = ref.read(tasksRepositoryProvider);
    final tasks = await repository.watchTasks().first;
    final byId = {for (final task in tasks) task.id: task};
    var completedCount = 0;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      for (final id in ids) {
        final task = byId[id];
        if (task == null) {
          continue;
        }
        if (!task.completed) {
          await repository.updateTask(
            taskId: id,
            title: task.title,
            description: task.description,
            deadline: task.deadline,
            priority: task.priority,
            status: TaskStatus.completed,
            completedAt: DateTime.now(),
            reminderOffsets: task.reminderOffsets,
            alarmEnabled: task.alarmEnabled,
          );
          completedCount += 1;
        }
        await _cancelTaskReminders(id);
      }
    });
    if (state.hasError) {
      throw state.error!;
    }
    return completedCount;
  }

  Future<int> deleteTasks(Iterable<int> taskIds) async {
    final ids = taskIds.toSet();
    if (ids.isEmpty) {
      return 0;
    }

    final repository = ref.read(tasksRepositoryProvider);
    var deletedCount = 0;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      for (final id in ids) {
        await _cancelTaskReminders(id);
        await repository.deleteTask(id);
        deletedCount += 1;
      }
    });
    if (state.hasError) {
      throw state.error!;
    }
    return deletedCount;
  }

  Future<int> archiveTasks(Iterable<int> taskIds) async {
    final ids = taskIds.toSet();
    if (ids.isEmpty) {
      return 0;
    }

    final repository = ref.read(tasksRepositoryProvider);
    final tasks = await repository.watchTasks().first;
    final byId = {for (final task in tasks) task.id: task};
    var archivedCount = 0;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      for (final id in ids) {
        final task = byId[id];
        if (task == null) {
          continue;
        }
        await repository.updateTask(
          taskId: id,
          title: task.title,
          description: task.description,
          deadline: null,
          priority: TaskPriority.neutral,
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
          reminderOffsets: const [],
          alarmEnabled: false,
        );
        await _cancelTaskReminders(id);
        archivedCount += 1;
      }
    });
    if (state.hasError) {
      throw state.error!;
    }
    return archivedCount;
  }
}

final taskWriteControllerProvider =
    AsyncNotifierProvider<TaskWriteController, void>(
      TaskWriteController.new,
    );
