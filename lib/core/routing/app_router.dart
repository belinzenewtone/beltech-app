import 'package:beltech/features/auth/presentation/auth_gate.dart';
import 'package:beltech/features/analytics/presentation/analytics_screen.dart';
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
import 'package:beltech/features/learning/presentation/screens/learning_screen.dart';
import 'package:beltech/features/planner/presentation/screens/planner_screen.dart';
import 'package:beltech/features/recurring/presentation/recurring_screen.dart';
import 'package:beltech/features/review/presentation/week_review_screen.dart';
import 'package:beltech/features/search/presentation/global_search_screen.dart';
import 'package:beltech/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:beltech/features/settings/presentation/screens/screen_lock_screen.dart';
import 'package:beltech/features/settings/presentation/settings_screen.dart';
import 'package:beltech/features/tasks/presentation/tasks_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: [
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
        builder: (context, state) => const WeekReviewScreen(),
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
        builder: (context, state) => const FeeAnalyticsScreen(),
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
    ],
  ),
);
