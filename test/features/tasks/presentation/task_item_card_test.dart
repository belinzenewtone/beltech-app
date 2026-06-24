import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/presentation/widgets/task_item_card.dart';
import 'package:beltech/features/tasks/presentation/widgets/task_item_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: SizedBox.expand(child: child)),
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
  completed: false,
  priority: TaskPriority.medium,
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
        completed: false,
        priority: TaskPriority.high,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(find.text('Check the diff carefully'), findsOneWidget);
    });

    testWidgets('does not show description widget when null', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));
      // Only the title text is present; description text absent
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('null'), findsNothing);
    });

    testWidgets('shows Urgent capsule for high priority', (tester) async {
      const task = TaskItem(
        id: 3,
        title: 'Fix crash',
        description: null,
        completed: false,
        priority: TaskPriority.high,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(find.text('Urgent'), findsOneWidget);
    });

    testWidgets('shows Important capsule for medium priority', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));
      expect(find.text('Important'), findsOneWidget);
    });

    testWidgets('shows Neutral capsule for low priority', (tester) async {
      const task = TaskItem(
        id: 4,
        title: 'Water plants',
        description: null,
        completed: false,
        priority: TaskPriority.low,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(find.text('Neutral'), findsOneWidget);
    });

    testWidgets('completed task shows Completed badge', (tester) async {
      const task = TaskItem(
        id: 5,
        title: 'Call dentist',
        description: null,
        completed: true,
        priority: TaskPriority.low,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('completed task title has strikethrough', (tester) async {
      const task = TaskItem(
        id: 6,
        title: 'Done task',
        description: null,
        completed: true,
        priority: TaskPriority.medium,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));

      final textWidget = tester.widget<Text>(find.text('Done task'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });
  });

  group('TaskItemCard — swipe backgrounds', () {
    testWidgets('complete swipe background uses successMuted colour',
        (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));

      // The Dismissible widget has a background for start-to-end swipe.
      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      final bg = dismissible.background as TaskSwipeBackground?;
      expect(bg?.color, AppColors.successMuted);
    });

    testWidgets('delete swipe background uses dangerMuted colour',
        (tester) async {
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

  group('TaskItemCard — icon button tooltips', () {
    testWidgets('toggle button tooltip is Mark complete for incomplete task',
        (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));
      // IconButton tooltip is on the first IconButton (toggle)
      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      expect(buttons.first.tooltip, 'Mark complete');
    });

    testWidgets('toggle button tooltip is Mark incomplete for done task',
        (tester) async {
      const task = TaskItem(
        id: 7,
        title: 'Done',
        description: null,
        completed: true,
        priority: TaskPriority.medium,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      expect(buttons.first.tooltip, 'Mark incomplete');
    });

    testWidgets('edit button tooltip is Edit task', (tester) async {
      await tester.pumpWidget(_wrap(_card(task: _base)));
      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      expect(buttons.last.tooltip, 'Edit task');
    });

    testWidgets('selection mode changes toggle tooltip to Select task',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_card(task: _base, selectionMode: true, selected: false)),
      );
      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      expect(buttons.first.tooltip, 'Select task');
    });

    testWidgets(
        'selection mode changes toggle tooltip to Deselect task when selected',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_card(task: _base, selectionMode: true, selected: true)),
      );
      final buttons = tester.widgetList<IconButton>(find.byType(IconButton));
      expect(buttons.first.tooltip, 'Deselect task');
    });

    testWidgets('edit button is hidden in selection mode', (tester) async {
      await tester.pumpWidget(
        _wrap(_card(task: _base, selectionMode: true, selected: false)),
      );
      // Only the toggle button present; edit hidden
      expect(find.byType(IconButton), findsOneWidget);
    });
  });

  group('TaskItemCard — interactions', () {
    testWidgets('tapping toggle button calls onToggle', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(_card(
            task: _base,
            onToggle: () async {
              called = true;
            })),
      );
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('tapping edit button calls onEdit', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(_card(
            task: _base,
            onEdit: () async {
              called = true;
            })),
      );
      await tester.tap(find.byType(IconButton).last);
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('busy state disables toggle button', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(_card(
          task: _base,
          busy: true,
          onToggle: () async {
            called = true;
          },
        )),
      );
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(called, isFalse);
    });

    testWidgets('tapping card in selection mode calls onSelectToggle',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(_card(
          task: _base,
          selectionMode: true,
          selected: false,
          onSelectToggle: () {
            called = true;
          },
        )),
      );
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });
  });

  group('TaskItemCard — due date display', () {
    testWidgets('shows Today badge for due date matching today',
        (tester) async {
      final today = DateTime.now();
      final task = TaskItem(
        id: 10,
        title: 'Today task',
        description: null,
        completed: false,
        priority: TaskPriority.medium,
        dueDate: DateTime(today.year, today.month, today.day, 23, 59),
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows date string for future task beyond tomorrow',
        (tester) async {
      final future = DateTime.now().add(const Duration(days: 10));
      final task = TaskItem(
        id: 11,
        title: 'Future task',
        description: null,
        completed: false,
        priority: TaskPriority.low,
        dueDate: future,
      );
      await tester.pumpWidget(_wrap(_card(task: task)));
      // Formatted as month/day/year
      expect(
        find.text('${future.month}/${future.day}/${future.year}'),
        findsOneWidget,
      );
    });
  });
}

