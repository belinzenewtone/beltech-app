import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_month_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('month grid renders event and task markers and supports tap', (
    tester,
  ) async {
    DateTime? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarMonthGrid(
            visibleMonth: DateTime(2026, 4, 1),
            selectedDay: DateTime(2026, 4, 3),
            eventTypes: const {3: CalendarEventType.work},
            taskDays: const {3, 4},
            maxWidth: 360,
            onSelect: (day) => selected = day,
          ),
        ),
      ),
    );

    final markerDots = find.byWidgetPredicate((widget) {
      if (widget is! Container) {
        return false;
      }
      final constraints = widget.constraints;
      if (constraints == null ||
          constraints.minWidth != 4 ||
          constraints.maxWidth != 4 ||
          constraints.minHeight != 4 ||
          constraints.maxHeight != 4) {
        return false;
      }
      final decoration = widget.decoration;
      return decoration is BoxDecoration && decoration.shape == BoxShape.circle;
    });

    expect(markerDots, findsNWidgets(3));

    await tester.tap(find.text('4'));
    expect(selected, DateTime(2026, 4, 4));
  });
}
