enum CalendarEventPriority {
  neutral('Neutral'),
  important('Important'),
  urgent('Urgent');

  const CalendarEventPriority(this.label);
  final String label;
}

enum CalendarEventType {
  work('Work'),
  personal('Personal'),
  health('Health'),
  finance('Finance'),
  other('Other');

  const CalendarEventType(this.label);
  final String label;
}

enum CalendarEventKind {
  event('Event'),
  birthday('Birthday'),
  anniversary('Anniversary'),
  countdown('Countdown');

  const CalendarEventKind(this.label);
  final String label;
}

enum RepeatRule {
  never('Never'),
  daily('Daily'),
  monFri('Mon – Fri'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const RepeatRule(this.label);
  final String label;
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.completed,
    required this.priority,
    this.kind = CalendarEventKind.event,
    this.type = CalendarEventType.personal,
    this.endAt,
    this.note,
    this.reminderOffsets = const [],
    this.alarmEnabled = false,
    this.allDay = false,
    this.repeatRule = RepeatRule.never,
    this.guests = '',
    this.timeZoneId = '',
    this.reminderTimeOfDayMinutes = 480,
  });

  final int id;
  final String title;
  final DateTime startAt;
  final bool completed;
  final CalendarEventPriority priority;
  final CalendarEventKind kind;
  final CalendarEventType type;
  final DateTime? endAt;
  final String? note;
  final List<int> reminderOffsets;
  final bool alarmEnabled;
  final bool allDay;
  final RepeatRule repeatRule;
  final String guests;
  final String timeZoneId;
  final int reminderTimeOfDayMinutes;

  CalendarEvent copyWith({
    int? id,
    String? title,
    DateTime? startAt,
    bool? completed,
    CalendarEventPriority? priority,
    CalendarEventKind? kind,
    CalendarEventType? type,
    DateTime? endAt,
    String? note,
    List<int>? reminderOffsets,
    bool? alarmEnabled,
    bool? allDay,
    RepeatRule? repeatRule,
    String? guests,
    String? timeZoneId,
    int? reminderTimeOfDayMinutes,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        startAt: startAt ?? this.startAt,
        completed: completed ?? this.completed,
        priority: priority ?? this.priority,
        kind: kind ?? this.kind,
        type: type ?? this.type,
        endAt: endAt ?? this.endAt,
        note: note ?? this.note,
        reminderOffsets: reminderOffsets ?? this.reminderOffsets,
        alarmEnabled: alarmEnabled ?? this.alarmEnabled,
        allDay: allDay ?? this.allDay,
        repeatRule: repeatRule ?? this.repeatRule,
        guests: guests ?? this.guests,
        timeZoneId: timeZoneId ?? this.timeZoneId,
        reminderTimeOfDayMinutes:
            reminderTimeOfDayMinutes ?? this.reminderTimeOfDayMinutes,
      );

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
          kind == other.kind &&
          type == other.type &&
          endAt == other.endAt &&
          note == other.note &&
          alarmEnabled == other.alarmEnabled &&
          allDay == other.allDay &&
          repeatRule == other.repeatRule &&
          guests == other.guests &&
          timeZoneId == other.timeZoneId &&
          reminderTimeOfDayMinutes == other.reminderTimeOfDayMinutes &&
          _listEquals(reminderOffsets, other.reminderOffsets);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startAt,
    completed,
    priority,
    kind,
    type,
    endAt,
    note,
    alarmEnabled,
    allDay,
    repeatRule,
    guests,
    timeZoneId,
    reminderTimeOfDayMinutes,
    reminderOffsets.isEmpty ? null : reminderOffsets.length,
  );

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

CalendarEventPriority calendarEventPriorityFromRaw(String raw) {
  return switch (raw.trim().toLowerCase()) {
    'urgent' || 'high' => CalendarEventPriority.urgent,
    'important' || 'medium' => CalendarEventPriority.important,
    _ => CalendarEventPriority.neutral,
  };
}

String calendarEventPriorityToRaw(CalendarEventPriority priority) {
  return priority.name;
}

CalendarEventType calendarEventTypeFromRaw(String raw) {
  return switch (raw.trim().toLowerCase()) {
    'work' => CalendarEventType.work,
    'personal' => CalendarEventType.personal,
    'finance' => CalendarEventType.finance,
    'health' => CalendarEventType.health,
    'other' || 'general' => CalendarEventType.other,
    _ => CalendarEventType.other,
  };
}

String calendarEventTypeToRaw(CalendarEventType type) {
  return type.name;
}

CalendarEventKind calendarEventKindFromRaw(String raw) {
  return switch (raw.trim().toLowerCase()) {
    'birthday' => CalendarEventKind.birthday,
    'anniversary' => CalendarEventKind.anniversary,
    'countdown' => CalendarEventKind.countdown,
    _ => CalendarEventKind.event,
  };
}

String calendarEventKindToRaw(CalendarEventKind kind) {
  return kind.name;
}

RepeatRule repeatRuleFromRaw(String raw) {
  return switch (raw.trim().toLowerCase().replaceAll('_', '')) {
    'daily' => RepeatRule.daily,
    'monfri' || 'mon-fri' || 'mon fri' => RepeatRule.monFri,
    'weekly' => RepeatRule.weekly,
    'monthly' => RepeatRule.monthly,
    'yearly' => RepeatRule.yearly,
    _ => RepeatRule.never,
  };
}

String repeatRuleToRaw(RepeatRule rule) {
  return rule.name;
}
