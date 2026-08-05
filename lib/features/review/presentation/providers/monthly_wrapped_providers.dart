import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/review/domain/entities/monthly_wrapped_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StreamProvider so data auto-refreshes on any transaction change.
final monthlyWrappedProvider = StreamProvider.family<MonthlyWrappedData, (int, int)>(
  (ref, args) {
    final (year, month) = args;
    return ref.watch(monthlyWrappedRepositoryProvider).watchWrapped(
          year: year,
          month: month,
        );
  },
);
