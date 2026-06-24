import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/presentation/widgets/import_health_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('ImportHealthBanner', () {
    testWidgets('hides itself when there is nothing to report', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ImportHealthBanner(
            metrics: ExpenseImportMetrics(
              reviewQueueCount: 0,
              quarantineCount: 0,
              retryQueueCount: 0,
              failedQueueCount: 0,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.textContaining('pending'), findsNothing);
      expect(find.textContaining('duplicates'), findsNothing);
      expect(find.textContaining('parse failed'), findsNothing);
    });

    testWidgets('shows pending, duplicates and parse failures', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ImportHealthBanner(
            metrics: ExpenseImportMetrics(
              reviewQueueCount: 3,
              quarantineCount: 2,
              retryQueueCount: 1,
              failedQueueCount: 4,
            ),
          ),
        ),
      );

      expect(find.text('1 pending · 3 duplicates · 6 parse failed'), findsOne);
    });
  });
}
