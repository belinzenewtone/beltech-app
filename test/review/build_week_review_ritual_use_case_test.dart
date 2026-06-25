import 'package:beltech/features/review/domain/entities/week_review_data.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_ritual_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = BuildWeekReviewRitualUseCase();

  WeekReviewData buildData({
    required int completedThisWeek,
    required int tasksDueThisWeek,
    required double weeklySpendKes,
    required double weeklyIncomeKes,
  }) {
    return WeekReviewData(
      completedThisWeek: completedThisWeek,
      completedLastWeek: 2,
      pendingCount: 3,
      tasksDueThisWeek: tasksDueThisWeek,
      tasksDueLastWeek: 4,
      weeklySpendKes: weeklySpendKes,
      previousWeeklySpendKes: 2000,
      weeklyIncomeKes: weeklyIncomeKes,
      previousWeeklyIncomeKes: 3000,
      upcomingEventsCount: 1,
      insights: const [],
    );
  }

  test('returns positive ritual when momentum is strong', () {
    final ritual = useCase(
      buildData(
        completedThisWeek: 4,
        tasksDueThisWeek: 5,
        weeklySpendKes: 2500,
        weeklyIncomeKes: 6000,
      ),
    );

    expect(ritual.headline, 'Protect your momentum');
    expect(ritual.ctaLabel, 'Start ritual');
    expect(ritual.focusLabel, 'Keep');
  });

  test('returns spending reset ritual for negative net weeks', () {
    final ritual = useCase(
      buildData(
        completedThisWeek: 3,
        tasksDueThisWeek: 4,
        weeklySpendKes: 7200,
        weeklyIncomeKes: 4000,
      ),
    );

    expect(ritual.headline, 'Reset your spending rhythm');
    expect(ritual.ctaLabel, 'Review spending');
    expect(ritual.focusLabel, 'Trim');
  });

  test('returns task cadence ritual when completion lags', () {
    final ritual = useCase(
      buildData(
        completedThisWeek: 1,
        tasksDueThisWeek: 4,
        weeklySpendKes: 2800,
        weeklyIncomeKes: 4500,
      ),
    );

    expect(ritual.headline, 'Tighten your task cadence');
    expect(ritual.ctaLabel, 'Review priorities');
    expect(ritual.focusLabel, 'Finish');
  });
}
