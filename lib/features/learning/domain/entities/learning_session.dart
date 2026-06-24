class LearningSession {
  const LearningSession({
    required this.id,
    required this.topic,
    required this.durationMinutes,
    required this.date,
  });

  final int id;
  final String topic;
  final int durationMinutes;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          topic == other.topic &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode => Object.hash(id, topic, durationMinutes);
}
