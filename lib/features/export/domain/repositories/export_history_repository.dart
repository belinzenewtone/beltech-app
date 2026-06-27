import 'package:beltech/features/export/domain/entities/export_history_entry.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';

abstract class ExportHistoryRepository {
  Future<List<ExportHistoryEntry>> readHistory();
  Future<void> addResult(ExportResult result);
  Future<void> clearHistory();
}
