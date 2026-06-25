import 'package:beltech/core/di/review_use_case_providers.dart';
import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/di/feature_flag_providers.dart';
import 'package:beltech/features/review/domain/entities/week_review_ritual.dart';
import 'package:beltech/features/review/presentation/providers/review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weekReviewRitualEnabledProvider = FutureProvider<bool>(
  (ref) =>
      ref.watch(featureFlagProvider(FeatureFlag.weeklyReviewRitual).future),
);

final weekReviewRitualProvider = Provider<AsyncValue<WeekReviewRitual?>>((ref) {
  final enabledState = ref.watch(weekReviewRitualEnabledProvider);
  final reviewState = ref.watch(weekReviewDataProvider);

  if (enabledState.isLoading || reviewState.isLoading) {
    return const AsyncLoading();
  }
  if (enabledState.hasError) {
    return AsyncError(
      enabledState.error!,
      enabledState.stackTrace ?? StackTrace.current,
    );
  }
  if (reviewState.hasError) {
    return AsyncError(
      reviewState.error!,
      reviewState.stackTrace ?? StackTrace.current,
    );
  }
  if (!(enabledState.valueOrNull ?? false)) {
    return const AsyncData(null);
  }

  final review = reviewState.valueOrNull;
  if (review == null) {
    return const AsyncLoading();
  }

  final useCase = ref.watch(buildWeekReviewRitualUseCaseProvider);
  return AsyncData(useCase(review));
});
