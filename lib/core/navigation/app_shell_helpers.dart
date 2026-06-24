import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns the per-tab accent radial glow colour used by [AppShell].
///
/// Tab mapping: 0 = Home, 1 = Finance, 2 = Calendar, 3 = AI, 4 = Profile.
Color accentForTab(int tab) {
  const palette = [
    AppColors.accent,   // Home     – primary blue
    AppColors.azure,    // Finance  – azure blue
    AppColors.teal,     // Calendar – teal
    AppColors.violet,   // AI       – violet
    AppColors.sky,      // Profile  – sky blue
  ];
  return palette[tab % palette.length];
}

Future<void> cleanupNotificationReminders(WidgetRef ref) async {
  final notifications = ref.read(localNotificationServiceProvider);
  final tasksRepository = ref.read(tasksRepositoryProvider);
  final calendarRepository = ref.read(calendarRepositoryProvider);
  final tasks = await tasksRepository.watchTasks().first;
  final activeTaskIds = tasks
      .where((task) =>
          !task.completed &&
          task.dueDate != null &&
          task.dueDate!.isAfter(DateTime.now()))
      .map((task) => task.id);

  final from = DateTime.now().subtract(const Duration(days: 1));
  final to = DateTime.now().add(const Duration(days: 365 * 2));
  final events = await calendarRepository.watchEventsInRange(from, to).first;
  final activeEventIds = events
      .where(
          (event) => !event.completed && event.startAt.isAfter(DateTime.now()))
      .map((event) => event.id);

  await notifications.cleanupOrphanedReminders(
    activeTaskIds: activeTaskIds,
    activeEventIds: activeEventIds,
  );
}
