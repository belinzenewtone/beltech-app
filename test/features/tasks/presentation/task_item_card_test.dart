import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/presentation/providers/time_tracking_providers.dart';
import 'package:beltech/features/tasks/presentation/widgets/task_item_card.dart';
import 'package:beltech/features/tasks/presentation/widgets/task_item_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      timerTickProvider.overrideWith((ref) => Stream.value(DateTime.now())),
      activeTimerProvider.overrideWith((ref, taskId) => Future.value(null)),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: SizedBox.expand(child: child)),
    ),
  );
}

TaskItemCard _card({
  required TaskItem task,
  bool selectionMode = false,
  bool selected = false,
  bool busy = false,
  VoidCallback? onSelectToggle,
  Future<void> Function()? onToggle,
  Future<void> Function()? onEdit,
  Future<void> Function()? onDelete,
}) {
  return TaskItemCard(
    task: task,
    selectionMode: selectionMode,
    selected: selected,
    onSelectToggle: onSelectToggle ?? () {},
    onToggle: onToggle ?? () async {},
    busy: busy,
    onEdit: onEdit ?? () async {},
    onDelete: onDelete ?? () async {},
  );
}

const _base = TaskItem(
  id: 1,
  title: 'Buy groceries',
  description: null,
  status: TaskStatus.pending,
  priority: TaskPriority.important,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TaskItemCard — rendering', () {
    testWidgets('shows task title', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('shows description when provided', (tester) async {
      const task = TaskItem(
        id: 2,
        title: 'Review PR',
        description: 'Check the diff carefully',
        status: TaskStatus.pending,
        priority: TaskPriority.urgent,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(find.text('Check the diff carefully'), findsOneWidget);
    });

    testWidgets('does not show description widget when null', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('null'), findsNothing);
    });

    testWidgets('shows formatted deadline when no description', (tester) async {
      final deadline = DateTime.now().add(const Duration(days: 5));
      final task = TaskItem(
        id: 3,
        title: 'Future task',
        status: TaskStatus.pending,
        priority: TaskPriority.neutral,
        deadline: deadline,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(
        find.text(DateFormat('MMM d, h:mm a').format(deadline)),
        findsOneWidget,
      );
    });

    testWidgets('shows No deadline when nothing else to display', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));
      expect(find.text('No deadline'), findsOneWidget);
    });

    testWidgets('completed task title has strikethrough', (tester) async {
      const task = TaskItem(
        id: 4,
        title: 'Done task',
        status: TaskStatus.completed,
        priority: TaskPriority.important,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));

      final textWidget = tester.widget<Text>(find.text('Done task'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });
  });

  group('TaskItemCard — status circle tooltips', () {
    testWidgets('pending task tooltip is Mark complete', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));
      expect(find.byTooltip('Mark complete'), findsOneWidget);
    });

    testWidgets('completed task tooltip is Mark incomplete', (tester) async {
      const task = TaskItem(
        id: 5,
        title: 'Done',
        status: TaskStatus.completed,
        priority: TaskPriority.important,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(find.byTooltip('Mark incomplete'), findsOneWidget);
    });

    testWidgets('selection mode unselected keeps Mark complete tooltip', (tester) async {
      await tester.pumpWidget(
        _wrap(_card(task: _base, selectionMode: true, selected: false)),
      );
      expect(find.byTooltip('Mark complete'), findsOneWidget);
    });

    testWidgets('selection mode selected tooltip is Deselect', (tester) async {
      await tester.pumpWidget(
        _wrap(_card(task: _base, selectionMode: true, selected: true)),
      );
      expect(find.byTooltip('Deselect'), findsOneWidget);
    });
  });

  group('TaskItemCard — swipe backgrounds', () {
    testWidgets('complete swipe background uses successMuted colour', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      final bg = dismissible.background as TaskSwipeBackground?;
      expect(bg?.color, AppColors.successMuted);
    });

    testWidgets('delete swipe background uses dangerMuted colour', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      final bg = dismissible.secondaryBackground as TaskSwipeBackground?;
      expect(bg?.color, AppColors.dangerMuted);
    });

    testWidgets('swipe is disabled in selection mode', (tester) async {
      await tester.pumpWidget(
        _wrap(_card(task: _base, selectionMode: true, selected: false)),
      );
      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.none);
    });

    testWidgets('swipe is disabled when busy', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base, busy: true)));
      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.none);
    });
  });

  group('TaskItemCard — interactions', () {
    testWidgets('tapping status circle calls onToggle', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          _card(
            task: _base,
            onToggle: () async {
              called = true;
            },
          ),
        ),
      );
      await tester.tap(find.byTooltip('Mark complete'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('tapping card calls onEdit', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          _card(
            task: _base,
            onEdit: () async {
              called = true;
            },
          ),
        ),
      );
      await tester.tap(find.text('Buy groceries'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('busy state disables status circle', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          _card(
            task: _base,
            busy: true,
            onToggle: () async {
              called = true;
            },
          ),
        ),
      );
      await tester.tap(find.byTooltip('Mark complete'));
      await tester.pumpAndSettle();
      expect(called, isFalse);
    });

    testWidgets('selection mode tapping status circle calls onSelectToggle', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          _card(
            task: _base,
            selectionMode: true,
            selected: false,
            onSelectToggle: () {
              called = true;
            },
          ),
        ),
      );
      await tester.tap(find.byTooltip('Mark complete'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });
  });

  group('TaskItemCard — due date display', () {
    testWidgets('shows today for deadline matching today', (tester) async {
      final today = DateTime.now();
      final task = TaskItem(
        id: 10,
        title: 'Today task',
        status: TaskStatus.pending,
        priority: TaskPriority.important,
        deadline: DateTime(today.year, today.month, today.day, 23, 59),
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(find.textContaining('today'), findsOneWidget);
    });

    testWidgets('shows date string for future task beyond tomorrow', (
      tester,
    ) async {
      final future = DateTime.now().add(const Duration(days: 10));
      final task = TaskItem(
        id: 11,
        title: 'Future task',
        status: TaskStatus.pending,
        priority: TaskPriority.neutral,
        deadline: future,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(
        find.text(DateFormat('MMM d, h:mm a').format(future)),
        findsOneWidget,
      );
    });
  });
}
