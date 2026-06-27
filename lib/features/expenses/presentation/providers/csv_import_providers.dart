import 'dart:async';

import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/features/expenses/domain/services/csv_import_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final csvImportServiceProvider = Provider<CsvImportService>(
  (_) => const CsvImportService(),
);

final csvImportPreviewProvider = StateProvider<CsvImportPreview?>((_) => null);

final csvImportColumnMappingProvider = StateProvider<Map<String, String?>>(
  (_) => const {
    'date': null,
    'title': null,
    'category': null,
    'amount': null,
    'balance': null,
  },
);

enum CsvImportStatus { idle, loading, previewReady, importing, done, error }

final csvImportStatusProvider = StateProvider<CsvImportStatus>(
  (_) => CsvImportStatus.idle,
);

final csvImportErrorProvider = StateProvider<String?>((_) => null);

class CsvImportController extends AutoDisposeAsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  Future<void> loadPreview(String filePath) async {
    ref.read(csvImportStatusProvider.notifier).state = CsvImportStatus.loading;
    ref.read(csvImportErrorProvider.notifier).state = null;
    try {
      final service = ref.read(csvImportServiceProvider);
      final preview = await service.preview(filePath);
      ref.read(csvImportPreviewProvider.notifier).state = preview;
      ref.read(csvImportStatusProvider.notifier).state =
          CsvImportStatus.previewReady;

      final mapping = <String, String?>{};
      for (final entry in preview.detectedMappings.entries) {
        switch (entry.value) {
          case 'occurred_at':
            mapping['date'] = entry.key;
          case 'title':
            mapping['title'] = entry.key;
          case 'category':
            mapping['category'] = entry.key;
          case 'amountKes':
            mapping['amount'] = entry.key;
          case 'balanceAfterKes':
            mapping['balance'] = entry.key;
        }
      }
      ref.read(csvImportColumnMappingProvider.notifier).state = mapping;
    } catch (e) {
      ref.read(csvImportStatusProvider.notifier).state = CsvImportStatus.error;
      ref.read(csvImportErrorProvider.notifier).state = '$e';
    }
  }

  Future<int> runImport({
    required String filePath,
    required Map<String, String> columnMapping,
  }) async {
    ref.read(csvImportStatusProvider.notifier).state =
        CsvImportStatus.importing;
    ref.read(csvImportErrorProvider.notifier).state = null;
    try {
      final service = ref.read(csvImportServiceProvider);
      final store = ref.read(appDriftStoreProvider);
      final count = await service.import(filePath, columnMapping, store);
      ref.read(csvImportStatusProvider.notifier).state = CsvImportStatus.done;
      state = AsyncData(count);
      return count;
    } catch (e) {
      ref.read(csvImportStatusProvider.notifier).state = CsvImportStatus.error;
      ref.read(csvImportErrorProvider.notifier).state = '$e';
      rethrow;
    }
  }

  void reset() {
    ref.read(csvImportPreviewProvider.notifier).state = null;
    ref.read(csvImportColumnMappingProvider.notifier).state = const {
      'date': null,
      'title': null,
      'category': null,
      'amount': null,
      'balance': null,
    };
    ref.read(csvImportStatusProvider.notifier).state = CsvImportStatus.idle;
    ref.read(csvImportErrorProvider.notifier).state = null;
  }
}

final csvImportControllerProvider =
    AutoDisposeAsyncNotifierProvider<CsvImportController, int>(
      CsvImportController.new,
    );
