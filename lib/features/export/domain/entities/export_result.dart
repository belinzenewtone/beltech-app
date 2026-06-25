enum ExportScope { all, expenses, incomes, tasks, events, budgets, recurring }

class ExportResult {
  const ExportResult({
    required this.filePath,
    required this.rowsExported,
    required this.scope,
    this.isEncrypted = false,
  });

  final String filePath;
  final int rowsExported;
  final ExportScope scope;
  final bool isEncrypted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportResult &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          rowsExported == other.rowsExported &&
          scope == other.scope;

  @override
  int get hashCode => Object.hash(filePath, rowsExported, scope);
}
