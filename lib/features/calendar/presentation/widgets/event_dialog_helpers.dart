import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

Future<DateTime?> pickEventDateTime(
  BuildContext context,
  DateTime initial,
) async {
  final now = DateTime.now();
  final pickedDate = await showDatePicker(
    context: context,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
    initialDate: initial,
  );
  if (pickedDate == null || !context.mounted) {
    return null;
  }
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (pickedTime == null) {
    return null;
  }
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}

String formatEventDateTimeLabel(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(value);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(value),
    alwaysUse24HourFormat: true,
  );
  return '$date at $time';
}

({String label, Color color}) eventPriorityOption(
  CalendarEventPriority priority,
) {
  return switch (priority) {
    CalendarEventPriority.high => (label: 'Urgent', color: AppColors.danger),
    CalendarEventPriority.medium => (
      label: 'Important',
      color: AppColors.warning,
    ),
    CalendarEventPriority.low => (label: 'Neutral', color: AppColors.accent),
  };
}

({String label, Color color, IconData icon}) eventTypeOption(
  CalendarEventType type,
) {
  return switch (type) {
    CalendarEventType.work => (
      label: 'Work',
      color: AppColors.accent,
      icon: Icons.work_outline,
    ),
    CalendarEventType.personal => (
      label: 'Personal',
      color: AppColors.violet,
      icon: Icons.person_outline,
    ),
    CalendarEventType.finance => (
      label: 'Finance',
      color: AppColors.teal,
      icon: Icons.account_balance_wallet_outlined,
    ),
    CalendarEventType.health => (
      label: 'Health',
      color: AppColors.orange,
      icon: Icons.favorite_outline,
    ),
    CalendarEventType.general => (
      label: 'General',
      color: AppColors.slate,
      icon: Icons.event_note_outlined,
    ),
    CalendarEventType.birthday => (
      label: 'Birthday',
      color: AppColors.warning,
      icon: Icons.cake_outlined,
    ),
    CalendarEventType.anniversary => (
      label: 'Anniversary',
      color: AppColors.danger,
      icon: Icons.celebration_outlined,
    ),
    CalendarEventType.countdown => (
      label: 'Countdown',
      color: AppColors.accent,
      icon: Icons.timer_outlined,
    ),
  };
}
