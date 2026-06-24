enum CalendarEventPriority { high, medium, low }

enum CalendarEventType { work, personal, finance, health, general, birthday, anniversary, countdown }

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.completed,
    required this.priority,
    this.type = CalendarEventType.general,
    this.endAt,
    this.note,
    this.reminderEnabled = true,
    this.reminderMinutesBefore = 15,
  });

  final int id;
  final String title;
  final DateTime startAt;
  final bool completed;
  final CalendarEventPriority priority;
  final CalendarEventType type;
  final DateTime? endAt;
  final String? note;
  final bool reminderEnabled;
  final int reminderMinutesBefore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          startAt == other.startAt &&
          completed == other.completed &&
          priority == other.priority &&
          type == other.type &&
          endAt == other.endAt &&
          note == other.note &&
          reminderEnabled == other.reminderEnabled &&
          reminderMinutesBefore == other.reminderMinutesBefore;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startAt,
    completed,
    priority,
    type,
    endAt,
    note,
    reminderEnabled,
    reminderMinutesBefore,
  );
}

CalendarEventType calendarEventTypeFromRaw(String raw) {
  return switch (raw.trim().toLowerCase()) {
    'work' => CalendarEventType.work,
    'personal' => CalendarEventType.personal,
    'finance' => CalendarEventType.finance,
    'health' => CalendarEventType.health,
    'birthday' => CalendarEventType.birthday,
    'anniversary' => CalendarEventType.anniversary,
    'countdown' => CalendarEventType.countdown,
    _ => CalendarEventType.general,
  };
}

String calendarEventTypeToRaw(CalendarEventType type) {
  return type.name;
}
