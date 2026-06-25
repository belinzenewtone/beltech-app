import 'package:beltech/features/learning/domain/entities/learning_session.dart';

abstract interface class LearningRepository {
  Stream<List<LearningSession>> watchSessions();
  Future<List<LearningSession>> loadSessions();
  Future<void> addSession({
    required String topic,
    required int durationMinutes,
    required DateTime date,
  });
  Future<void> deleteSession(int id);
  Future<int> currentStreak();
  Future<int> monthlyMinutes(DateTime month);
}
