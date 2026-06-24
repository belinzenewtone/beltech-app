import 'package:beltech/features/review/domain/entities/week_review_data.dart';

class WeekReviewRitual {
  const WeekReviewRitual({
    required this.headline,
    required this.summary,
    required this.focusLabel,
    required this.focusDetail,
    required this.tone,
    required this.ctaLabel,
  });

  final String headline;
  final String summary;
  final String focusLabel;
  final String focusDetail;
  final WeekReviewInsightTone tone;
  final String ctaLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekReviewRitual &&
          runtimeType == other.runtimeType &&
          headline == other.headline &&
          summary == other.summary &&
          focusLabel == other.focusLabel &&
          focusDetail == other.focusDetail &&
          tone == other.tone &&
          ctaLabel == other.ctaLabel;

  @override
  int get hashCode =>
      Object.hash(headline, summary, focusLabel, focusDetail, tone, ctaLabel);
}
