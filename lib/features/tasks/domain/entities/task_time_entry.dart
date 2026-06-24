class TaskTimeEntry {
  const TaskTimeEntry({
    this.id,
    required this.taskId,
    this.startedAt,
    this.endedAt,
    this.durationSec,
    this.note,
  });

  final int? id;
  final int taskId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSec;
  final String? note;

  bool get isRunning => startedAt != null && endedAt == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTimeEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          taskId == other.taskId &&
          startedAt == other.startedAt &&
          endedAt == other.endedAt &&
          durationSec == other.durationSec &&
          note == other.note;

  @override
  int get hashCode => Object.hash(id, taskId, startedAt, endedAt, durationSec, note);
}
