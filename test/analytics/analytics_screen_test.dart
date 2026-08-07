import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_theme.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/domain/entities/monthly_breakdown_data.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:beltech/features/analytics/presentation/analytics_screen.dart';
import 'package:beltech/features/analytics/presentation/category_drill_down_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AnalyticsScreen', () {
    late _FakeAnalyticsRepository repo;

    setUp(() {
      repo = _FakeAnalyticsRepository();
    });

    Widget build() {
      final router = GoRouter(
        initialLocation: '/analytics',
        routes: [
          GoRoute(
            path: '/analytics',
            builder: (_, _) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/analytics/category/:category',
            builder: (_, state) {
              final category = Uri.decodeComponent(
                  state.pathParameters['category'] ?? 'Other');
              final extra = state.extra;
              if (extra is AnalyticsCategoryShare) {
                return CategoryDrillDownScreen(
                  category: category,
                  totalKes: extra.totalKes,
                  share: extra,
                );
              }
              return CategoryDrillDownScreen(
                category: category,
                totalKes: 0,
                txCount: 0,
              );
            },
          ),
        ],
      );
      return ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
    }

    testWidgets('renders segment control and Analytics content by default',
        (tester) async {
      await tester.pumpWidget(build());
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Analytics'), findsWidgets);
      expect(find.text('Insights'), findsOneWidget);
      // Analytics default content: summary cards
      expect(find.text('Spend'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
    });

    testWidgets('switching to Insights shows trend + history + anatomy',
        (tester) async {
      await tester.pumpWidget(build());
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Insights'));
      // Pump past the pulse-bar entry timers (0 and 120 ms) so none stay
      // pending at teardown.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Monthly Trend'), findsOneWidget);
      expect(find.text('Spending Insights'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Spend Anatomy'), findsOneWidget);
      expect(find.text('Average Monthly'), findsOneWidget);
      expect(find.text('Total Tracked'), findsOneWidget);
    });

    testWidgets('category cards navigate to the drill-down', (tester) async {
      await tester.pumpWidget(build());
      await tester.pump(const Duration(milliseconds: 400));

      final food = find.text('Food');
      await tester.ensureVisible(food);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(food);
      await tester.pump(const Duration(milliseconds: 400));
      // Let the drill-down's FutureBuilder resolve.
      await tester.pump(const Duration(milliseconds: 200));

      // The drill-down shows a real transaction list from the fake repo.
      await tester.scrollUntilVisible(
        find.text('Transactions'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Restaurant A'), findsOneWidget);
    });
  });
}

class _FakeAnalyticsRepository implements AnalyticsRepository {
  @override
  Stream<AnalyticsSnapshot> watchSnapshot(AnalyticsPeriod period) {
    // Stream.value emits on listen so the StreamProvider resolves reliably.
    return Stream<AnalyticsSnapshot>.value(_snapshot());
  }

  @override
  Future<double> getMonthTotalSpend(int year, int month) async => 0;

  @override
  Future<String?> getTopCategoryAllTime() async => 'Food';

  @override
  Future<List<CategoryTransaction>> getCategoryTransactions(
    String category, {
    DateTime? start,
    DateTime? end,
  }) async {
    return [
      CategoryTransaction(
        id: 1,
        title: 'Restaurant A',
        amountKes: 1200,
        occurredAt: DateTime(2026, 1, 10, 12, 0),
      ),
      CategoryTransaction(
        id: 2,
        title: 'Cafe B',
        amountKes: 400,
        occurredAt: DateTime(2026, 1, 9, 8, 30),
      ),
    ];
  }

  AnalyticsSnapshot _snapshot() {
    const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    final months = List<MonthlyTotalPoint>.generate(6, (i) {
      final offset = 5 - i;
      var m = now.month - offset;
      var y = now.year;
      while (m <= 0) {
        m += 12;
        y--;
      }
      return MonthlyTotalPoint(
        periodKey: '$y-${m.toString().padLeft(2, '0')}',
        monthLabel: monthNames[m - 1],
        totalKes: i == 5 ? 4000 : 2000.0 * (i + 1),
        year: y,
        month: m,
        monthOffset: -offset,
        txCount: i == 5 ? 10 : 5,
      );
    });
    return AnalyticsSnapshot(
      totalSpentThisPeriodKes: 5000,
      totalIncomeThisPeriodKes: 20000,
      previousPeriodTotalKes: 4000,
      averageDailySpendingKes: 250,
      feesPaidKes: 120,
      totalTxCount: 12,
      microTxCount: 6,
      mediumTxCount: 4,
      largeTxCount: 2,
      totalTasksCompleted: 3,
      totalTasksPending: 2,
      totalEventsThisMonth: 1,
      productivityScore: 60,
      weeklySpending: const [
        AnalyticsPoint(label: 'Mon', amountKes: 100),
        AnalyticsPoint(label: 'Tue', amountKes: 300),
        AnalyticsPoint(label: 'Wed', amountKes: 200),
        AnalyticsPoint(label: 'Thu', amountKes: 0),
        AnalyticsPoint(label: 'Fri', amountKes: 500),
        AnalyticsPoint(label: 'Sat', amountKes: 150),
        AnalyticsPoint(label: 'Sun', amountKes: 250),
      ],
      monthlySpending: const [],
      categoryBreakdown: const [
        AnalyticsCategoryShare(
          category: 'Food',
          totalKes: 3000,
          percentage: 60,
          weeklySparkline: [100, 0, 200, 0, 300, 0, 100, 50],
        ),
        AnalyticsCategoryShare(
          category: 'Transport',
          totalKes: 2000,
          percentage: 40,
          weeklySparkline: [50, 0, 0, 100, 0, 200, 0, 0],
        ),
      ],
      topMerchants: const [],
      monthlyHistory: months,
      monthBreakdown: [
        MonthlyBreakdownData(
          periodKey: months.last.periodKey,
          monthLabel: months.last.monthLabel,
          year: months.last.year,
          month: months.last.month,
          totalKes: 4000,
          previousMonthTotalKes: 6000,
          txCount: 10,
          topCategories: const [
            MonthlyBreakdownCategory(category: 'Food', totalKes: 2400, pct: 60),
            MonthlyBreakdownCategory(category: 'Transport', totalKes: 1600, pct: 40),
          ],
        ),
      ],
      postIncomeAvgDailySpendKes: 800,
      otherDaysAvgDailySpendKes: 300,
      topFeeCategory: 'Food',
      incomeEventsCount: 2,
      avgMonthlyExpenseKes: 2500,
      totalTrackedKes: 15000,
      topCategoryAllTime: 'Food',
      topCategoryAllTimePct: 55.0,
      trend: 'increasing',
    );
  }
}
