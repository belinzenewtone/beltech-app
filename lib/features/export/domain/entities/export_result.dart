import 'package:beltech/features/export/domain/entities/export_format.dart';

enum ExportScope { all, expenses, incomes, tasks, events, budgets, recurring }

String exportScopeLabel(ExportScope scope) {
  return switch (scope) {
    ExportScope.all => 'All Data',
    ExportScope.expenses => 'Transactions',
    ExportScope.incomes => 'Incomes',
    ExportScope.tasks => 'Tasks',
    ExportScope.events => 'Events',
    ExportScope.budgets => 'Budgets',
    ExportScope.recurring => 'Recurring',
  };
}

String exportScopePreviewLabel(ExportScope scope) {
  return switch (scope) {
    ExportScope.all => 'Total items',
    ExportScope.expenses => 'transactions',
    ExportScope.incomes => 'incomes',
    ExportScope.tasks => 'tasks',
    ExportScope.events => 'events',
    ExportScope.budgets => 'budgets',
    ExportScope.recurring => 'recurring rules',
  };
}

class ExportResult {
  ExportResult({
    required this.filePath,
    required this.rowsExported,
    required this.scope,
    required this.format,
    this.isEncrypted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String filePath;
  final int rowsExported;
  final ExportScope scope;
  final ExportFormat format;
  final bool isEncrypted;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportResult &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          rowsExported == other.rowsExported &&
          scope == other.scope &&
          format == other.format &&
          isEncrypted == other.isEncrypted &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    filePath,
    rowsExported,
    scope,
    format,
    isEncrypted,
    createdAt,
  );
}
