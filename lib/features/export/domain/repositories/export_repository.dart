import 'package:beltech/features/export/domain/entities/export_result.dart';

abstract class ExportRepository {
  Future<ExportResult> exportCsv({
    required ExportScope scope,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ExportResult> exportEncryptedCsv({
    required ExportScope scope,
    required String password,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ExportResult> exportJson({
    required ExportScope scope,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ExportResult> exportEncryptedJson({
    required ExportScope scope,
    required String password,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ExportResult> exportPdfStatement({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Map<ExportScope, int>> previewCounts();
}
