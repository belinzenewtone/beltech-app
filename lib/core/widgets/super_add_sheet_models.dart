enum SuperEntryKind { task, event, birthday, anniversary, countdown }

enum SuperEntryPriority { high, medium, low }

enum SuperEntryEventType { work, personal, finance, health, general }

class SuperEntryInput {
  const SuperEntryInput({
    required this.kind,
    required this.title,
    required this.description,
    this.priority,
    this.dueAt,
    this.startAt,
    this.endAt,
    this.eventType,
    this.year,
    this.repeatYearly = false,
    this.remind3DaysBefore = false,
    this.reminderOffsets,
    this.alarmEnabled = false,
  });

  final SuperEntryKind kind;
  final String title;
  final String? description;
  final SuperEntryPriority? priority;
  final DateTime? dueAt;
  final DateTime? startAt;
  final DateTime? endAt;
  final SuperEntryEventType? eventType;
  final int? year;
  final bool repeatYearly;
  final bool remind3DaysBefore;
  final List<int>? reminderOffsets;
  final bool alarmEnabled;
}
