import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/review/domain/entities/monthly_wrapped_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a [MonthlyWrappedData] for [year]/[month].
/// Backed by the MonthlyWrappedRepositoryImpl.
final monthlyWrappedProvider = FutureProvider.family<MonthlyWrappedData, (int, int)>(
  (ref, args) {
    final (year, month) = args;
    return ref.watch(monthlyWrappedRepositoryProvider).loadWrapped(
          year: year,
          month: month,
        );
  },
);
