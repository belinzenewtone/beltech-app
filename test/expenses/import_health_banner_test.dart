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
              duplicateSkipCount: 5,
            ),
          ),
        ),
      );

      // "duplicates" reflects skipped duplicates (duplicateSkipCount), not the
      // review queue count. Parse failures = quarantine + failed.
      expect(find.text('1 pending · 5 duplicates · 6 parse failed'), findsOne);
    });

    testWidgets('review queue items are not reported as duplicates',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ImportHealthBanner(
            metrics: ExpenseImportMetrics(
              reviewQueueCount: 7,
              quarantineCount: 0,
              retryQueueCount: 0,
              failedQueueCount: 0,
              duplicateSkipCount: 0,
            ),
          ),
        ),
      );

      // Review-queue items are awaiting approval — they must not surface as
      // "duplicates" (which would mislead the user into thinking imports are
      // being skipped).
      expect(find.textContaining('duplicates'), findsNothing);
      expect(find.textContaining('parse failed'), findsNothing);
    });
  });
}
