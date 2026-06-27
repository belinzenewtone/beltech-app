import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/assistant/domain/entities/assistant_message.dart';
import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/review/domain/entities/week_review_data.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AssistantMessage uses value equality', () {
    final createdAt = DateTime(2026, 3, 29, 10, 0);
    const id = 'msg-1';
    const text = 'Hello';

    final a = AssistantMessage(
      id: id,
      text: text,
      isUser: true,
      createdAt: createdAt,
    );
    final b = AssistantMessage(
      id: id,
      text: text,
      isUser: true,
      createdAt: createdAt,
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('BudgetSnapshot compares nested lists by value', () {
    final month = DateTime(2026, 3, 1);
    final a = BudgetSnapshot(
      month: month,
      items: const [
        BudgetCategoryItem(
          category: 'Food',
          monthlyLimitKes: 1200,
          spentKes: 300,
        ),
      ],
    );
    final b = BudgetSnapshot(
      month: month,
      items: const [
        BudgetCategoryItem(
          category: 'Food',
          monthlyLimitKes: 1200,
          spentKes: 300,
        ),
      ],
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('AnalyticsSnapshot compares trend/category lists by value', () {
    const a = AnalyticsSnapshot(
      totalSpentThisMonthKes: 1000,
      averageDailySpendingKes: 50,
      totalTasksCompleted: 8,
      totalTasksPending: 2,
      totalEventsThisMonth: 4,
      productivityScore: 87.5,
      weeklySpending: [AnalyticsPoint(label: 'Mon', amountKes: 300)],
      monthlySpending: [AnalyticsPoint(label: 'W1', amountKes: 700)],
      categoryBreakdown: [
        AnalyticsCategoryShare(category: 'Food', totalKes: 700, percentage: 70),
      ],
      topMerchants: [
        AnalyticsMerchantShare(merchant: 'Shop', totalKes: 700, transactionCount: 3),
      ],
    );
    const b = AnalyticsSnapshot(
      totalSpentThisMonthKes: 1000,
      averageDailySpendingKes: 50,
      totalTasksCompleted: 8,
      totalTasksPending: 2,
      totalEventsThisMonth: 4,
      productivityScore: 87.5,
      weeklySpending: [AnalyticsPoint(label: 'Mon', amountKes: 300)],
      monthlySpending: [AnalyticsPoint(label: 'W1', amountKes: 700)],
      categoryBreakdown: [
        AnalyticsCategoryShare(category: 'Food', totalKes: 700, percentage: 70),
      ],
      topMerchants: [
        AnalyticsMerchantShare(merchant: 'Shop', totalKes: 700, transactionCount: 3),
      ],
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('WeekReviewData compares insight list by value', () {
    const a = WeekReviewData(
      completedThisWeek: 4,
      completedLastWeek: 3,
      pendingCount: 2,
      tasksDueThisWeek: 5,
      tasksDueLastWeek: 4,
      weeklySpendKes: 1200,
      previousWeeklySpendKes: 1000,
      weeklyIncomeKes: 3000,
      previousWeeklyIncomeKes: 2800,
      upcomingEventsCount: 1,
      insights: [
        WeekReviewInsight(
          title: 'Solid week',
          detail: 'You stayed consistent.',
          tone: WeekReviewInsightTone.positive,
        ),
      ],
    );
    const b = WeekReviewData(
      completedThisWeek: 4,
      completedLastWeek: 3,
      pendingCount: 2,
      tasksDueThisWeek: 5,
      tasksDueLastWeek: 4,
      weeklySpendKes: 1200,
      previousWeeklySpendKes: 1000,
      weeklyIncomeKes: 3000,
      previousWeeklyIncomeKes: 2800,
      upcomingEventsCount: 1,
      insights: [
        WeekReviewInsight(
          title: 'Solid week',
          detail: 'You stayed consistent.',
          tone: WeekReviewInsightTone.positive,
        ),
      ],
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('GlobalSearchResult uses value equality', () {
    final date = DateTime(2026, 3, 29);
    final a = GlobalSearchResult(
      kind: GlobalSearchKind.task,
      primaryText: 'Review budget',
      secondaryText: 'High priority',
      trailingText: 'Today',
      recordId: 12,
      recordDate: date,
    );
    final b = GlobalSearchResult(
      kind: GlobalSearchKind.task,
      primaryText: 'Review budget',
      secondaryText: 'High priority',
      trailingText: 'Today',
      recordId: 12,
      recordDate: date,
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });
}
