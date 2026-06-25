enum TaskPriority { high, medium, low }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.priority,
    this.dueDate,
    this.reminderEnabled = true,
    this.reminderMinutesBefore = 30,
  });

  final int id;
  final String title;
  final String? description;
  final bool completed;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool reminderEnabled;
  final int reminderMinutesBefore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          completed == other.completed &&
          priority == other.priority &&
          dueDate == other.dueDate &&
          reminderEnabled == other.reminderEnabled &&
          reminderMinutesBefore == other.reminderMinutesBefore;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    completed,
    priority,
    dueDate,
    reminderEnabled,
    reminderMinutesBefore,
  );
}
