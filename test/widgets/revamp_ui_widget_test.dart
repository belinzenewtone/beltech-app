import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expenses_snapshot_content.dart';
import 'package:beltech/features/home/presentation/widgets/home_week_review_ritual_card.dart';
import 'package:beltech/features/review/domain/entities/week_review_ritual.dart';
import 'package:beltech/features/review/presentation/providers/review_providers.dart';
import 'package:beltech/features/review/presentation/providers/review_ritual_providers.dart';
import 'package:beltech/features/review/presentation/week_review_screen.dart';
import 'package:beltech/features/settings/presentation/widgets/notification_preferences_section.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
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
    expect(find.text('2 upcoming events'), findsOneWidget);
    expect(find.text('Cash flow is healthy'), findsOneWidget);
    expect(find.text('Open Analytics'), findsOneWidget);
    expect(find.text('Review Budget'), findsOneWidget);
    expect(find.text('Review Income'), findsOneWidget);
  });

  testWidgets('security and notification settings expose revamp controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionLockSettingsProvider.overrideWith(
            (ref) async => const SessionLockSettings(gracePeriodSeconds: 30),
          ),
          notificationsEnabledProvider.overrideWith((ref) async => true),
          budgetAlertsEnabledProvider.overrideWith((ref) async => true),
          dailyDigestEnabledProvider.overrideWith((ref) async => true),
          weeklyReviewNotificationsEnabledProvider.overrideWith(
            (ref) async => true,
          ),
        ],
        child: _wrap(
          const SingleChildScrollView(
            child: Column(
              children: [
                SettingsSecurityCard(
                  state: AuthState(
                    biometricSupported: true,
                    biometricEnabled: true,
                    isAuthenticating: false,
                  ),
                ),
                NotificationPreferencesSection(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Relock Delay'), findsOneWidget);
    expect(find.text('Weekly Review'), findsOneWidget);
    expect(find.text('Biometric Lock'), findsOneWidget);
    expect(find.text('Daily Summary'), findsOneWidget);
  });

  testWidgets(
    'notification child preferences lock when notifications are disabled',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsEnabledProvider.overrideWith((ref) async => false),
            budgetAlertsEnabledProvider.overrideWith((ref) async => true),
            dailyDigestEnabledProvider.overrideWith((ref) async => true),
            weeklyReviewNotificationsEnabledProvider.overrideWith(
              (ref) async => true,
            ),
          ],
          child: _wrap(const NotificationPreferencesSection()),
        ),
      );
      await tester.pumpAndSettle();

      final budgetSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.widgetWithText(SettingsRow, 'Budget Alerts'),
          matching: find.byType(Switch),
        ),
      );
      final digestSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.widgetWithText(SettingsRow, 'Daily Summary'),
          matching: find.byType(Switch),
        ),
      );
      final ritualSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.widgetWithText(SettingsRow, 'Weekly Review'),
          matching: find.byType(Switch),
        ),
      );

      expect(budgetSwitch.onChanged, isNull);
      expect(digestSwitch.onChanged, isNull);
      expect(ritualSwitch.onChanged, isNull);
    },
  );

  testWidgets(
    'finance import pipeline shows replay, paybill, and fuliza sections',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExpensesSnapshotContent(
            snapshot: ExpensesSnapshot(
              todayKes: 400,
              weekKes: 1200,
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
            importMetrics: const ExpenseImportMetrics(
              reviewQueueCount: 1,
              quarantineCount: 1,
              retryQueueCount: 2,
              failedQueueCount: 1,
            ),
            reviewItems: [
              ExpenseReviewItem(
                id: 1,
                title: 'ATM Withdrawal',
                category: 'Cash',
                amountKes: 300,
                occurredAt: DateTime(2026, 3, 20, 10, 0),
                confidence: 0.68,
                rawMessage: 'sample',
              ),
            ],
            quarantineItems: [
              ExpenseQuarantineItem(
                id: 1,
                reason: 'Low confidence classification',
                confidence: 0.42,
                rawMessage: 'sample',
                createdAt: DateTime(2026, 3, 20, 12, 0),
              ),
            ],
            paybillProfiles: [
              PaybillProfile(
                id: 1,
                paybill: '998877',
                displayName: 'KPLC Prepaid',
                lastSeenAt: DateTime(2026, 3, 21, 9, 0),
                usageCount: 3,
              ),
            ],
            fulizaEvents: [
              FulizaLifecycleEvent(
                id: 1,
                mpesaCode: 'AA12BB34CC',
                kind: FulizaLifecycleKind.draw,
                amountKes: 500,
                occurredAt: DateTime(2026, 3, 21, 10, 0),
              ),
              FulizaLifecycleEvent(
                id: 2,
                mpesaCode: 'DD56EE78FF',
                kind: FulizaLifecycleKind.repayment,
                amountKes: 200,
                occurredAt: DateTime(2026, 3, 21, 12, 0),
              ),
            ],
            onApproveReview: (_) {},
            onRejectReview: (_) {},
            onDismissQuarantine: (_) {},
            onReplayImportQueue: () async {},
            onMerchantTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replay Import Queue'), findsOneWidget);
      expect(find.text('Paybill Registry'), findsOneWidget);
      expect(find.text('Fuliza'), findsOneWidget);
      expect(find.text('Outstanding'), findsOneWidget);
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
