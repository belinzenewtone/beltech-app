import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/core/theme/app_theme.dart';
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
import 'package:beltech/features/settings/presentation/widgets/settings_security_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('weekly ritual card matches revamp baseline', (tester) async {
    tester.view.physicalSize = const Size(440, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          weekReviewRitualProvider
              .overrideWith((ref) => const AsyncData(ritual)),
        ],
        child: _wrap(
          const KeyedSubtree(
            key: Key('weekly-ritual-card'),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: HomeWeekReviewRitualCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('weekly-ritual-card')),
      matchesGoldenFile('../goldens/weekly_ritual_card.png'),
    );
  });

  testWidgets('security and notification controls match baseline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(460, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          const KeyedSubtree(
            key: Key('settings-revamp-controls'),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingsSecurityCard(
                    state: AuthState(
                      biometricSupported: true,
                      biometricEnabled: true,
                      isAuthenticating: false,
                    ),
                  ),
                  SizedBox(height: 20),
                  NotificationPreferencesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('settings-revamp-controls')),
      matchesGoldenFile('../goldens/settings_revamp_controls.png'),
    );
  });

  testWidgets('finance import intelligence card matches baseline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(520, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        KeyedSubtree(
          key: const Key('finance-import-intelligence'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ExpensesSnapshotContent(
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('finance-import-intelligence')),
      matchesGoldenFile('../goldens/finance_import_intelligence.png'),
    );
  });

  testWidgets('week review screen matches baseline', (tester) async {
    tester.view.physicalSize = const Size(500, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          weekReviewRitualProvider
              .overrideWith((ref) => const AsyncData(ritual)),
        ],
        child: _wrap(
          const KeyedSubtree(
            key: Key('week-review-screen'),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: WeekReviewScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('week-review-screen')),
      matchesGoldenFile('../goldens/week_review_screen.png'),
    );
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: SizedBox.expand(child: child),
    ),
  );
}
