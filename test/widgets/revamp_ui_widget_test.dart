import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expenses_snapshot_content.dart';
import 'package:beltech/features/home/presentation/widgets/home_week_review_ritual_card.dart';
import 'package:beltech/features/review/domain/entities/week_review_ritual.dart';
import 'package:beltech/features/review/presentation/providers/review_providers.dart';
import 'package:beltech/features/review/presentation/providers/review_ritual_providers.dart';
import 'package:beltech/features/review/presentation/week_review_screen.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_security_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('home ritual card renders the ritual content', (tester) async {
    const ritual = WeekReviewRitual(
      headline: 'Protect your momentum',
      summary: 'Stay focused on your strongest weekly habit.',
      focusLabel: 'Keep',
      focusDetail: 'Carry your routine into next week.',
      tone: WeekReviewInsightTone.positive,
      ctaLabel: 'Start ritual',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weekReviewRitualProvider.overrideWith(
            (ref) => const AsyncData(ritual),
          ),
        ],
        child: _wrap(const HomeWeekReviewRitualCard()),
      ),
    );

    expect(find.textContaining('WEEK OF'), findsOneWidget);
    expect(find.text('Protect your momentum'), findsOneWidget);
  });

  testWidgets('week review screen shows ritual and upcoming events', (
    tester,
  ) async {
    const data = WeekReviewData(
      completedThisWeek: 3,
      completedLastWeek: 2,
      pendingCount: 4,
      tasksDueThisWeek: 5,
      tasksDueLastWeek: 4,
      weeklySpendKes: 1800,
      previousWeeklySpendKes: 1400,
      weeklyIncomeKes: 4000,
      previousWeeklyIncomeKes: 3200,
      upcomingEventsCount: 2,
      insights: [
        WeekReviewInsight(
          title: 'Cash flow is healthy',
          detail: 'You stayed positive this week.',
          tone: WeekReviewInsightTone.positive,
        ),
      ],
    );
    const ritual = WeekReviewRitual(
      headline: 'Close the week with clarity',
      summary: 'Reflect and line up the next week.',
      focusLabel: 'Plan',
      focusDetail: 'Check your next event and prepare early.',
      tone: WeekReviewInsightTone.neutral,
      ctaLabel: 'Open week review',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weekReviewDataProvider.overrideWith((ref) => const AsyncData(data)),
          weekReviewRitualProvider.overrideWith(
            (ref) => const AsyncData(ritual),
          ),
        ],
        child: _wrapPage(const WeekReviewScreen()),
      ),
    );

    expect(find.text('Close the week with clarity'), findsOneWidget);
    expect(find.text('Tasks Done'), findsOneWidget);
    expect(find.text('Cash flow is healthy'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
  });

  testWidgets('security settings expose revamp controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionLockSettingsProvider.overrideWith(
            (ref) async => const SessionLockSettings(gracePeriodSeconds: 30),
          ),
        ],
        child: _wrap(
          const SettingsSecurityCard(
            state: AuthState(
              biometricSupported: true,
              biometricEnabled: true,
              isAuthenticating: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Relock Delay'), findsOneWidget);
    expect(find.text('Biometric Lock'), findsOneWidget);
  });

  testWidgets(
    'finance snapshot shows summary, budget, and transaction sections',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExpensesSnapshotContent(
            snapshot: ExpensesSnapshot(
              todayKes: 400,
              weekKes: 1200,
              monthKes: 3500,
              categories: const [
                CategoryExpenseTotal(category: 'Bills', totalKes: 800),
              ],
              transactions: [
                ExpenseItem(
                  id: 1,
                  title: 'KPLC Prepaid',
                  category: 'Bills',
                  amountKes: 800,
                  occurredAt: DateTime(2026, 3, 21, 8, 0),
                ),
              ],
            ),
            selectedFilter: ExpenseFilter.all,
            busy: false,
            searchQuery: '',
            onFilterChanged: (_) {},
            onEditExpense: (_) {},
            onDeleteExpense: (_) {},
            onMerchantTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsWidgets);
      expect(find.text('Week'), findsWidgets);
      expect(find.text('Month'), findsWidgets);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox.expand(child: child)),
  );
}

Widget _wrapPage(Widget child) {
  return MaterialApp(home: child);
}
