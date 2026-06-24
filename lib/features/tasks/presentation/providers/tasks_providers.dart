import 'dart:async';

import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class TaskWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addQuickTask() async {
    final now = DateTime.now();
    await addTask(
      title: 'New Task ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      dueDate: now.add(const Duration(days: 1)),
      priority: TaskPriority.medium,
    );
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.addTask(
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        reminderEnabled: reminderEnabled,
        reminderMinutesBefore: reminderMinutesBefore,
      );
      if (dueDate != null && reminderEnabled) {
        await _scheduleCreatedTaskReminder(
          repository: repository,
          notifications: notifications,
          title: title,
          dueDate: dueDate,
          priority: priority,
          reminderMinutesBefore: reminderMinutesBefore,
        );
      }
    });
  }

  Future<void> toggleTask({
    required int taskId,
    required bool completed,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    final tasks = await repository.watchTasks().first;
    final taskBeforeChange = tasks
        .where((item) => item.id == taskId)
        .firstOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.toggleCompleted(taskId: taskId, completed: completed);
      if (completed) {
        await notifications.cancelTaskReminder(taskId);
      } else if (taskBeforeChange?.dueDate != null &&
          taskBeforeChange!.reminderEnabled) {
        await notifications.scheduleTaskReminder(
          taskId: taskId,
          title: taskBeforeChange.title,
          dueDate: taskBeforeChange.dueDate!,
          minutesBefore: taskBeforeChange.reminderMinutesBefore,
        );
      }
    });
  }

  Future<void> updateTask({
    required int taskId,
    required String title,
    String? description,
    required DateTime? dueDate,
    required TaskPriority priority,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 30,
  }) async {
    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        reminderEnabled: reminderEnabled,
        reminderMinutesBefore: reminderMinutesBefore,
      );
      if (dueDate == null || !reminderEnabled) {
        await notifications.cancelTaskReminder(taskId);
      } else {
        await notifications.scheduleTaskReminder(
          taskId: taskId,
          title: title,
          dueDate: dueDate,
          minutesBefore: reminderMinutesBefore,
        );
      }
    });
  }

  Future<void> deleteTask(int taskId) async {
    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await notifications.cancelTaskReminder(taskId);
      await repository.deleteTask(taskId);
    });
  }

  Future<int> completeTasks(Iterable<int> taskIds) async {
    final ids = taskIds.toSet();
    if (ids.isEmpty) {
      return 0;
    }

    final repository = ref.read(tasksRepositoryProvider);
    final notifications = ref.read(localNotificationServiceProvider);
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
          await repository.toggleCompleted(taskId: id, completed: true);
          completedCount += 1;
        }
        await notifications.cancelTaskReminder(id);
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
    final notifications = ref.read(localNotificationServiceProvider);
    var deletedCount = 0;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      for (final id in ids) {
        await notifications.cancelTaskReminder(id);
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
    final notifications = ref.read(localNotificationServiceProvider);
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
          dueDate: null,
          priority: TaskPriority.low,
        );
        await repository.toggleCompleted(taskId: id, completed: true);
        await notifications.cancelTaskReminder(id);
        archivedCount += 1;
      }
    });
    if (state.hasError) {
      throw state.error!;
    }
    return archivedCount;
  }

  Future<void> _scheduleCreatedTaskReminder({
    required TasksRepository repository,
    required LocalNotificationService notifications,
    required String title,
    required DateTime dueDate,
    required TaskPriority priority,
    required int reminderMinutesBefore,
  }) async {
    try {
      final tasks = await repository.watchTasks().first;
      final created = tasks.where((task) {
        if (task.title != title || task.priority != priority) {
          return false;
        }
        final due = task.dueDate;
        if (due == null) {
          return false;
        }
        return due.year == dueDate.year &&
            due.month == dueDate.month &&
            due.day == dueDate.day;
      }).firstOrNull;
      if (created == null || created.dueDate == null) {
        return;
      }
      await notifications.scheduleTaskReminder(
        taskId: created.id,
        title: created.title,
        dueDate: created.dueDate!,
        minutesBefore: reminderMinutesBefore,
      );
    } catch (_) {
      return;
    }
  }
}

final taskWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<TaskWriteController, void>(
      TaskWriteController.new,
    );
