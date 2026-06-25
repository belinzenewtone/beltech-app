import 'package:beltech/features/review/domain/entities/week_review_data.dart';
import 'package:beltech/features/review/domain/entities/week_review_ritual.dart';

class BuildWeekReviewRitualUseCase {
  const BuildWeekReviewRitualUseCase();

  WeekReviewRitual call(WeekReviewData data) {
    if (data.netKes >= 0 && data.completionRateThisWeek >= 0.7) {
      return const WeekReviewRitual(
        headline: 'Protect your momentum',
        summary:
            'You kept cash flow positive and followed through on your priorities. Close the week with a quick reset.',
        focusLabel: 'Keep',
        focusDetail: 'Carry your strongest habit into next week.',
        tone: WeekReviewInsightTone.positive,
        ctaLabel: 'Start ritual',
      );
    }
    if (data.netKes < 0) {
      return const WeekReviewRitual(
        headline: 'Reset your spending rhythm',
        summary:
            'This week leaned negative, so the ritual should focus on one category to tighten before Monday.',
        focusLabel: 'Trim',
        focusDetail: 'Review the category that moved the most this week.',
        tone: WeekReviewInsightTone.caution,
        ctaLabel: 'Review spending',
      );
    }
    if (data.tasksDueThisWeek > 0 && data.completionRateThisWeek < 0.7) {
      return const WeekReviewRitual(
        headline: 'Tighten your task cadence',
        summary:
            'A short ritual now will help you cut carry-over work and start the next week with a cleaner slate.',
        focusLabel: 'Finish',
        focusDetail: 'Choose one pending task to close before the day ends.',
        tone: WeekReviewInsightTone.caution,
        ctaLabel: 'Review priorities',
      );
    }
    return WeekReviewRitual(
      headline: 'Close the week with clarity',
      summary:
          'Your signals are steady. Take a few minutes to reflect, reset, and line up the next week with intention.',
      focusLabel: 'Plan',
      focusDetail: data.upcomingEventsCount == 0
          ? 'Add one anchor event for the week ahead.'
          : 'Check your next event and prepare for it early.',
      tone: WeekReviewInsightTone.neutral,
      ctaLabel: 'Open week review',
    );
  }
}
