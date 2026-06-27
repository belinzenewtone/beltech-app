import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/export/domain/entities/export_format.dart';
import 'package:beltech/features/export/domain/entities/export_history_entry.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExportDateWindow { allTime, last7Days, last30Days, thisMonth, custom }

({DateTime? start, DateTime? end}) datesForWindow(ExportDateWindow window) {
  final now = DateTime.now();
  switch (window) {
    case ExportDateWindow.allTime:
      return (start: null, end: null);
    case ExportDateWindow.last7Days:
      final start = now.subtract(const Duration(days: 6));
      return (
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case ExportDateWindow.last30Days:
      final start = now.subtract(const Duration(days: 29));
      return (
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case ExportDateWindow.thisMonth:
      return (
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case ExportDateWindow.custom:
      return (start: null, end: null);
  }
}

class ExportController extends AutoDisposeAsyncNotifier<ExportResult?> {
  @override
  FutureOr<ExportResult?> build() => null;

  Future<ExportResult> export({
    required ExportScope scope,
    required ExportFormat format,
    required ExportDateWindow window,
    String? password,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final dates = datesForWindow(window);
    final startDate = window == ExportDateWindow.custom
        ? customStart
        : dates.start;
    final endDate = window == ExportDateWindow.custom ? customEnd : dates.end;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repo = ref.read(exportRepositoryProvider);
      final encrypted = password != null && password.isNotEmpty;
      final ExportResult exportResult;
      switch (format) {
        case ExportFormat.json:
          exportResult = encrypted
              ? await repo.exportEncryptedJson(
                  scope: scope,
                  password: password,
                  startDate: startDate,
                  endDate: endDate,
                )
              : await repo.exportJson(
                  scope: scope,
                  startDate: startDate,
                  endDate: endDate,
                );
        case ExportFormat.csv:
          exportResult = encrypted
              ? await repo.exportEncryptedCsv(
                  scope: scope,
                  password: password,
                  startDate: startDate,
                  endDate: endDate,
                )
              : await repo.exportCsv(
                  scope: scope,
                  startDate: startDate,
                  endDate: endDate,
                );
        case ExportFormat.pdf:
          if (encrypted) {
            throw Exception('PDF statements cannot be encrypted.');
          }
          exportResult = await repo.exportPdfStatement(
            startDate: startDate,
            endDate: endDate,
          );
      }
      await ref.read(exportHistoryRepositoryProvider).addResult(exportResult);
      return exportResult;
    });
    state = result;
    if (result.hasError) {
      throw result.error!;
    }
    return result.valueOrNull!;
  }

}

final exportControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExportController, ExportResult?>(
      ExportController.new,
    );

final exportPreviewCountsProvider = FutureProvider<Map<ExportScope, int>>((
  ref,
) {
  return ref.watch(exportRepositoryProvider).previewCounts();
});

final exportHistoryProvider = FutureProvider<List<ExportHistoryEntry>>((ref) {
  return ref.watch(exportHistoryRepositoryProvider).readHistory();
});
