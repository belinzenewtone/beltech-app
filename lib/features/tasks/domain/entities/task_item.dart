enum TaskPriority {
  neutral('Neutral'),
  important('Important'),
  urgent('Urgent');

  const TaskPriority(this.label);
  final String label;
}

enum TaskStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed');

  const TaskStatus(this.label);
  final String label;

  bool get isCompleted => this == TaskStatus.completed;
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.neutral,
    this.deadline,
    this.status = TaskStatus.pending,
    this.completedAt,
    this.reminderOffsets = const [],
    this.alarmEnabled = false,
  });

  final int id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? deadline;
  final TaskStatus status;
  final DateTime? completedAt;
  final List<int> reminderOffsets;
  final bool alarmEnabled;

  bool get completed => status.isCompleted;

  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? deadline,
    TaskStatus? status,
    DateTime? completedAt,
    List<int>? reminderOffsets,
    bool? alarmEnabled,
  }) =>
      TaskItem(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        deadline: deadline ?? this.deadline,
        status: status ?? this.status,
        completedAt: completedAt ?? this.completedAt,
        reminderOffsets: reminderOffsets ?? this.reminderOffsets,
        alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          priority == other.priority &&
          deadline == other.deadline &&
          status == other.status &&
          completedAt == other.completedAt &&
          _listEquals(reminderOffsets, other.reminderOffsets) &&
          alarmEnabled == other.alarmEnabled;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    priority,
    deadline,
    status,
    completedAt,
    alarmEnabled,
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
