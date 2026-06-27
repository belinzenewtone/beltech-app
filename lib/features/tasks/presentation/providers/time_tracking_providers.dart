import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/tasks/domain/entities/task_time_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeTimerProvider = FutureProvider.family<TaskTimeEntry?, int>((
  ref,
  taskId,
) {
  return ref.watch(timeTrackingRepositoryProvider).activeEntry(taskId);
});

final taskTotalTimeProvider = FutureProvider.family<int, int>((ref, taskId) {
  return ref.watch(timeTrackingRepositoryProvider).totalTrackedSeconds(taskId);
});

final timerTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

class TimerController extends AsyncNotifier<void> {
  TimerController(this.taskId);

  final int taskId;

  @override
  FutureOr<void> build() async {}

  Future<void> toggleTimer() async {
    final repo = ref.read(timeTrackingRepositoryProvider);
    final active = await repo.activeEntry(taskId);
    if (active != null && active.id != null) {
      await repo.stopTimer(active.id!);
    } else {
      await repo.startTimer(taskId);
    }
    ref.invalidate(activeTimerProvider(taskId));
    ref.invalidate(taskTotalTimeProvider(taskId));
  }
}

final timerControllerProvider =
    AsyncNotifierProvider.family<TimerController, void, int>(
      (taskId) => TimerController(taskId),
    );
