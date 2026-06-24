import 'package:beltech/features/review/domain/usecases/build_week_review_data_use_case.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_ritual_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final buildWeekReviewDataUseCaseProvider = Provider<BuildWeekReviewDataUseCase>(
  (_) => const BuildWeekReviewDataUseCase(),
);

final buildWeekReviewRitualUseCaseProvider =
    Provider<BuildWeekReviewRitualUseCase>(
  (_) => const BuildWeekReviewRitualUseCase(),
);
