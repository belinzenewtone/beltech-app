import 'package:beltech/features/export/domain/entities/export_format.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';

class ExportHistoryEntry {
  const ExportHistoryEntry({
    required this.filePath,
    required this.rowsExported,
    required this.scope,
    required this.format,
    required this.isEncrypted,
    required this.createdAt,
    this.status = 'SUCCESS',
  });

  final String filePath;
  final int rowsExported;
  final ExportScope scope;
  final ExportFormat format;
  final bool isEncrypted;
  final DateTime createdAt;
  final String status;

  factory ExportHistoryEntry.fromResult(ExportResult result) {
    return ExportHistoryEntry(
      filePath: result.filePath,
      rowsExported: result.rowsExported,
      scope: result.scope,
      format: result.format,
      isEncrypted: result.isEncrypted,
      createdAt: result.createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'filePath': filePath,
      'rowsExported': rowsExported,
      'scope': scope.name,
      'format': format.name,
      'isEncrypted': isEncrypted,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory ExportHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExportHistoryEntry(
      filePath: json['filePath'] as String? ?? '',
      rowsExported: json['rowsExported'] as int? ?? 0,
      scope: _parseScope(json['scope'] as String? ?? 'all'),
      format: _parseFormat(json['format'] as String? ?? 'csv'),
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'SUCCESS',
    );
  }

  static ExportScope _parseScope(String value) {
    return ExportScope.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExportScope.all,
    );
  }

  static ExportFormat _parseFormat(String value) {
    return ExportFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExportFormat.csv,
    );
  }
}
