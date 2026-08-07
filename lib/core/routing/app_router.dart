import 'package:beltech/features/auth/presentation/auth_gate.dart';
import 'package:beltech/features/analytics/presentation/analytics_screen.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/category_drill_down_screen.dart';
import 'package:beltech/features/bills/presentation/screens/bills_screen.dart';
import 'package:beltech/features/budget/presentation/budget_screen.dart';
import 'package:beltech/features/calendar/presentation/calendar_add_screen.dart';
import 'package:beltech/features/calendar/presentation/calendar_add_screen_models.dart';
import 'package:beltech/features/changelog/presentation/screens/changelog_screen.dart';
import 'package:beltech/features/events/presentation/events_screen.dart';
import 'package:beltech/features/export/presentation/export_screen.dart';
import 'package:beltech/features/finance_hub/presentation/finance_hub_screen.dart';
import 'package:beltech/features/insights/presentation/screens/insights_screen.dart';
import 'package:beltech/features/income/presentation/income_screen.dart';
import 'package:beltech/features/loans/presentation/screens/loans_screen.dart';
import 'package:beltech/features/goals/presentation/screens/goals_screen.dart';
import 'package:beltech/features/expenses/presentation/screens/categorize_screen.dart';
import 'package:beltech/features/expenses/presentation/screens/fee_analytics_screen.dart';
import 'package:beltech/features/expenses/presentation/screens/csv_import_screen.dart';
import 'package:beltech/features/expenses/presentation/screens/import_health_screen.dart';
import 'package:beltech/features/expenses/presentation/screens/merchant_detail_screen.dart';
import 'package:beltech/features/expenses/presentation/screens/quarantine_queue_screen.dart';
import 'package:beltech/features/expenses/presentation/screens/review_queue_screen.dart';
import 'package:beltech/features/learning/presentation/screens/learning_screen.dart';
import 'package:beltech/features/planner/presentation/screens/planner_screen.dart';
import 'package:beltech/features/recurring/presentation/recurring_screen.dart';
import 'package:beltech/features/review/presentation/week_review_screen.dart';
import 'package:beltech/features/review/presentation/monthly_wrapped_screen.dart';
import 'package:beltech/features/review/presentation/review_screen.dart';
import 'package:beltech/features/search/presentation/global_search_screen.dart';
import 'package:beltech/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:beltech/features/settings/presentation/screens/screen_lock_screen.dart';
import 'package:beltech/features/settings/presentation/settings_screen.dart';
import 'package:beltech/features/tasks/presentation/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/analytics/category/:category',
        name: 'category-drill-down',
        builder: (context, state) {
          final category = Uri.decodeComponent(
              state.pathParameters['category'] ?? 'Other');
          // Accept either an AnalyticsCategoryShare object (new tap path)
          // or a legacy Map<String, dynamic> (older call sites).
          final extra = state.extra;
          if (extra is AnalyticsCategoryShare) {
            return CategoryDrillDownScreen(
              category: category,
              totalKes: extra.totalKes,
              txCount: 0, // real count loaded by the screen's own query
              share: extra,
            );
          }
          final args = extra as Map<String, dynamic>?;
          return CategoryDrillDownScreen(
            category: category,
            totalKes: (args?['totalKes'] as double?) ?? 0,
            txCount: (args?['txCount'] as int?) ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: '/calendar-add',
        name: 'calendar-add',
        builder: (context, state) {
          final args = state.extra as CalendarAddInitialArgs?;
          return CalendarAddScreen(args: args);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/screen-lock',
        name: 'screen-lock',
        builder: (context, state) => const ScreenLockScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/budget',
        name: 'budget',
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        path: '/income',
        name: 'income',
        builder: (context, state) => const IncomeScreen(),
      ),
      GoRoute(
        path: '/recurring',
        name: 'recurring',
        builder: (context, state) => const RecurringScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/export',
        name: 'export',
        builder: (context, state) => const ExportScreen(),
      ),
      GoRoute(
        path: '/finance-hub',
        name: 'finance-hub',
        builder: (context, state) => const FinanceHubScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/insights',
        name: 'insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/week-review',
        name: 'week-review',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeekReviewScreen(),
          transitionsBuilder: (ctx, anim, sec, child) => _slideUpTransition(ctx, anim, sec, child),
        ),
      ),
      GoRoute(
        path: '/weekly-review',
        name: 'weekly-review',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ReviewScreen(),
          transitionsBuilder: (ctx, anim, sec, child) => _slideUpTransition(ctx, anim, sec, child),
        ),
      ),
      GoRoute(
        path: '/monthly-wrapped',
        name: 'monthly-wrapped',
        pageBuilder: (context, state) {
          final args = state.extra as (int, int)?;
          final year = args?.$1 ?? DateTime.now().year;
          final month = args?.$2 ?? DateTime.now().month;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MonthlyWrappedScreen(year: year, month: month),
            transitionsBuilder: (ctx, anim, sec, child) => _slideUpTransition(ctx, anim, sec, child),
          );
        },
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TasksScreen(),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/bills',
        name: 'bills',
        builder: (context, state) => const BillsScreen(),
      ),
      GoRoute(
        path: '/loans',
        name: 'loans',
        builder: (context, state) => const LoansScreen(),
      ),
      GoRoute(
        path: '/goals',
        name: 'goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/learning',
        name: 'learning',
        builder: (context, state) => const LearningScreen(),
      ),
      GoRoute(
        path: '/categorize',
        name: 'categorize',
        builder: (context, state) => const CategorizeScreen(),
      ),
      GoRoute(
        path: '/changelog',
        name: 'changelog',
        builder: (context, state) => const ChangelogScreen(),
      ),
      GoRoute(
        path: '/planner',
        name: 'planner',
        builder: (context, state) => const PlannerScreen(),
      ),
      GoRoute(
        path: '/merchant-detail',
        name: 'merchant-detail',
        builder: (context, state) {
          final title = state.extra as String? ?? '';
          return MerchantDetailScreen(merchantTitle: title);
        },
      ),
      GoRoute(
        path: '/fee-analytics',
        name: 'fee-analytics',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FeeAnalyticsScreen(),
          transitionsBuilder: (ctx, anim, sec, child) => _slideLeftTransition(ctx, anim, sec, child),
        ),
      ),
      GoRoute(
        path: '/csv-import',
        name: 'csv-import',
        builder: (context, state) => const CsvImportScreen(),
      ),
      GoRoute(
        path: '/import-health',
        name: 'import-health',
        builder: (context, state) => const ImportHealthScreen(),
      ),
      GoRoute(
        path: '/quarantine-queue',
        name: 'quarantine-queue',
        builder: (context, state) => const QuarantineQueueScreen(),
      ),
      GoRoute(
        path: '/review-queue',
        name: 'review-queue',
        builder: (context, state) => const ReviewQueueScreen(),
      ),
    ],
  ),
);

Widget _slideUpTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    ),
    child: FadeTransition(opacity: animation, child: child),
  );
}

Widget _slideLeftTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(0.15, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    ),
    child: FadeTransition(opacity: animation, child: child),
  );
}
