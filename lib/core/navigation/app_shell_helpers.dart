import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns the per-tab accent radial glow colour used by [AppShell].
///
/// Tab mapping: 0 = Home, 1 = Finance, 2 = Calendar, 3 = AI, 4 = Profile.
Color accentForTab(int tab) {
  const palette = [
    AppColors.accent, // Home     – primary blue
    AppColors.azure, // Finance  – azure blue
    AppColors.teal, // Calendar – teal
    AppColors.violet, // AI       – violet
    AppColors.sky, // Profile  – sky blue
  ];
  return palette[tab % palette.length];
}

/// True for events whose reminders must persist even when their anchor date has
/// passed — yearly-recurring occasions roll forward to the next year.
bool _isRecurringYearly(CalendarEvent event) =>
    event.repeatRule == RepeatRule.yearly ||
    event.kind == CalendarEventKind.anniversary ||
    event.kind == CalendarEventKind.birthday;

/// Rebuilds every OS-scheduled reminder from the database on launch. This is
/// the safety net that guarantees reminders still exist even if the OS dropped
/// a pending alarm (aggressive OEM battery managers, edge-case reboots, etc).
/// Every schedule* call cancels-then-reschedules, so this is fully idempotent.
Future<void> resyncNotificationSchedules(WidgetRef ref) async {
  final notifications = ref.read(localNotificationServiceProvider);

  // Make sure OS-level permissions are granted before (re)scheduling.
  await notifications.ensurePlatformPermissions();

  final now = DateTime.now();

  // Tasks — future deadlines with at least one reminder offset.
  final tasks = await ref.read(tasksRepositoryProvider).watchTasks().first;
  for (final task in tasks) {
    if (task.completed ||
        task.deadline == null ||
        !task.deadline!.isAfter(now) ||
        task.reminderOffsets.isEmpty) {
      continue;
    }
    await notifications.scheduleTaskReminder(
      taskId: task.id,
      title: task.title,
      deadline: task.deadline!,
      reminderOffsets: task.reminderOffsets,
      alarmEnabled: task.alarmEnabled,
    );
  }

  // Events — future one-offs plus all yearly-recurring occasions.
  final events =
      await ref.read(calendarRepositoryProvider).watchAllEvents().first;
  for (final event in events) {
    if (event.completed || event.reminderOffsets.isEmpty) {
      continue;
    }
    if (!event.startAt.isAfter(now) && !_isRecurringYearly(event)) {
      continue;
    }
    await notifications.scheduleEventReminder(
      eventId: event.id,
      title: event.title,
      startAt: event.startAt,
      kind: event.kind,
      reminderOffsets: event.reminderOffsets,
      alarmEnabled: event.alarmEnabled,
      allDay: event.allDay,
      reminderTimeOfDayMinutes: event.reminderTimeOfDayMinutes,
      repeatRule: event.repeatRule,
    );
  }

  // Bills — unpaid bills at their due date.
  final bills = await ref.read(billsRepositoryProvider).loadBills();
  for (final bill in bills) {
    if (bill.paid) {
      continue;
    }
    await notifications.scheduleBillReminder(
      billId: bill.id,
      billName: bill.name,
      amount: bill.amount,
      dueDate: bill.dueDate,
    );
  }

  // Singleton daily-repeating reminders.
  await notifications.scheduleDailyDigest();
  await notifications.scheduleLearningDailyReminder();

  // Finally prune anything left over from deleted records.
  await cleanupNotificationReminders(ref);
}

Future<void> cleanupNotificationReminders(WidgetRef ref) async {
  final notifications = ref.read(localNotificationServiceProvider);
  final tasksRepository = ref.read(tasksRepositoryProvider);
  final calendarRepository = ref.read(calendarRepositoryProvider);
  final billsRepository = ref.read(billsRepositoryProvider);
  final now = DateTime.now();

  final tasks = await tasksRepository.watchTasks().first;
  final activeTaskIds = tasks
      .where(
        (task) =>
            !task.completed &&
            task.deadline != null &&
            task.deadline!.isAfter(now),
      )
      .map((task) => task.id);

  // Include yearly-recurring events even when their anchor date is in the past
  // so their (legitimately still-scheduled) reminders are NOT pruned.
  final events = await calendarRepository.watchAllEvents().first;
  final activeEventIds = events
      .where(
        (event) =>
            !event.completed &&
            (event.startAt.isAfter(now) || _isRecurringYearly(event)),
      )
      .map((event) => event.id);

  final bills = await billsRepository.loadBills();
  final activeBillIds =
      bills.where((bill) => !bill.paid).map((bill) => bill.id);

  await notifications.cleanupOrphanedReminders(
    activeTaskIds: activeTaskIds,
    activeEventIds: activeEventIds,
    activeBillIds: activeBillIds,
  );
}
