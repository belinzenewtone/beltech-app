import 'package:beltech/data/local/drift/app_drift_records.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;

  setUp(() {
    store = AppDriftStore();
  });

  tearDown(() async {
    await store.dispose();
  });

  test('addTransaction updates expenses snapshot stream', () async {
    final initial = await store.watchExpensesSnapshot().first;
    final initialOther = _categoryTotal(initial.categories, 'Other');
    final nextSnapshot = store.watchExpensesSnapshot().skip(1).first;

    await store.addTransaction(
      title: 'Store Test',
      category: 'Other',
      amountKes: 321,
    );

    final updated = await nextSnapshot.timeout(const Duration(seconds: 2));
    final updatedOther = _categoryTotal(updated.categories, 'Other');

    expect(updated.transactions.length,
        greaterThanOrEqualTo(initial.transactions.length + 1));
    expect(updatedOther, greaterThan(initialOther));
  });

  test('addTask and toggleTaskCompletion publish updated tasks', () async {
    final afterAddFuture = store.watchTasks().firstWhere(
          (tasks) => tasks.any((task) => task.title == 'Follow up supplier'),
        );

    await store.addTask(
      title: 'Follow up supplier',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );

    final afterAdd = await afterAddFuture.timeout(const Duration(seconds: 2));
    final created =
        afterAdd.firstWhere((task) => task.title == 'Follow up supplier');
    expect(created.completed, isFalse);
    expect(created.priority, 'medium');

    final afterToggleFuture = store.watchTasks().firstWhere(
          (tasks) =>
              tasks.any((task) => task.id == created.id && task.completed),
        );
    await store.toggleTaskCompletion(taskId: created.id, completed: true);
    final afterToggle =
        await afterToggleFuture.timeout(const Duration(seconds: 2));
    final toggled = afterToggle.firstWhere((task) => task.id == created.id);
    expect(toggled.completed, isTrue);
  });

  test('addEvent updates selected-day event stream', () async {
    final day = DateTime.now();
    final nextEvents = store.watchEventsForDay(day).firstWhere(
          (events) => events.any((event) => event.title == 'Client follow-up'),
        );

    await store.addEvent(
      title: 'Client follow-up',
      startAt: DateTime(day.year, day.month, day.day, 15),
      endAt: DateTime(day.year, day.month, day.day, 16),
      note: 'Quick sync',
    );

    final updated = await nextEvents.timeout(const Duration(seconds: 2));
    expect(updated.any((event) => event.title == 'Client follow-up'), isTrue);
  });
}

double _categoryTotal(List<CategoryTotalRecord> categories, String name) {
  for (final category in categories) {
    if (category.category == name) {
      return category.totalKes;
    }
  }
  return 0;
}
