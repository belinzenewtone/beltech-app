import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/learning/data/repositories/learning_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late LearningRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = LearningRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('addSession and loadSessions persist correctly', () async {
    await repository.addSession(
      topic: 'Flutter State Management',
      durationMinutes: 45,
      date: DateTime(2024, 6, 1),
    );

    final sessions = await repository.loadSessions();
    expect(sessions.length, 1);
    expect(sessions.first.topic, 'Flutter State Management');
    expect(sessions.first.durationMinutes, 45);
  });

  test('deleteSession removes session', () async {
    await repository.addSession(
      topic: 'A',
      durationMinutes: 30,
      date: DateTime(2024, 6, 1),
    );
    final created = await repository.loadSessions();
    await repository.deleteSession(created.first.id);
    final afterDelete = await repository.loadSessions();
    expect(afterDelete, isEmpty);
  });

  test('currentStreak returns 0 when no sessions', () async {
    final streak = await repository.currentStreak();
    expect(streak, 0);
  });

  test('monthlyMinutes sums current month correctly', () async {
    final now = DateTime.now();
    await repository.addSession(topic: 'A', durationMinutes: 30, date: now);
    await repository.addSession(topic: 'B', durationMinutes: 60, date: now);
    await repository.addSession(
      topic: 'C',
      durationMinutes: 20,
      date: DateTime(now.year, now.month - 1, 1),
    );

    final minutes = await repository.monthlyMinutes(now);
    expect(minutes, 90);
  });
}
