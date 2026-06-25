import 'dart:io';

import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/export/data/services/csv_builder.dart';
import 'package:beltech/features/export/data/services/encrypted_export_service.dart';
import 'package:beltech/features/export/data/services/pdf_statement_service.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:beltech/features/export/domain/repositories/export_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl(
    this._store, {
    this._csvBuilder = const CsvBuilder(),
    this._encryptService = const EncryptedExportService(),
    this._pdfService = const PdfStatementService(),
  });

  final AppDriftStore _store;
  final CsvBuilder _csvBuilder;
  final EncryptedExportService _encryptService;
  final PdfStatementService _pdfService;

  @override
  Future<ExportResult> exportCsv({
    required ExportScope scope,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      throw Exception('CSV export is not supported on web builds.');
    }
    await _store.ensureInitialized();
    final exports = await _buildScopedExports(
      scope,
      startDate: startDate,
      endDate: endDate,
    );
    final sections = <String>[];
    var totalRows = 0;
    for (final export in exports) {
      sections.add('## ${export.name}');
      sections.add(export.csv);
      totalRows += export.rows;
    }
    final content = sections.join('\n');
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dateTag = _dateTag(startDate: startDate, endDate: endDate);
    final file = File(
      '${dir.path}${Platform.pathSeparator}dart2_export${dateTag}_$stamp.csv',
    );
    await file.writeAsString(content);
    return ExportResult(
      filePath: file.path,
      rowsExported: totalRows,
      scope: scope,
      isEncrypted: false,
    );
  }

  @override
  Future<ExportResult> exportEncryptedCsv({
    required ExportScope scope,
    required String password,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      throw Exception('Encrypted export is not supported on web builds.');
    }
    final plainResult = await exportCsv(
      scope: scope,
      startDate: startDate,
      endDate: endDate,
    );
    final plainText = await File(plainResult.filePath).readAsString();
    final encrypted = _encryptService.encrypt(
      plainText: plainText,
      password: password,
    );
    final encryptedFile = File('${plainResult.filePath}.enc');
    await encryptedFile.writeAsString(encrypted);
    // Remove plain file for security
    await File(plainResult.filePath).delete();
    return ExportResult(
      filePath: encryptedFile.path,
      rowsExported: plainResult.rowsExported,
      scope: scope,
      isEncrypted: true,
    );
  }

  @override
  Future<ExportResult> exportPdfStatement({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      throw Exception('PDF export is not supported on web builds.');
    }
    await _store.ensureInitialized();

    final txns = await _fetchTransactions(
      startDate: startDate,
      endDate: endDate,
    );
    final incs = await _fetchIncomes(startDate: startDate, endDate: endDate);

    final filePath = await _pdfService.generate(
      transactions: txns,
      incomes: incs,
      startDate: startDate,
      endDate: endDate,
    );

    return ExportResult(
      filePath: filePath,
      rowsExported: txns.length + incs.length,
      scope: ExportScope.all,
      isEncrypted: false,
    );
  }

  Future<List<PdfTransactionRow>> _fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <Object?>[];
    var query =
        'SELECT title, category, amount, occurred_at FROM transactions WHERE transaction_type = ?';
    params.add('expense');
    if (startDate != null) {
      params.add(startDate.millisecondsSinceEpoch);
      query += ' AND occurred_at >= ?';
    }
    if (endDate != null) {
      params.add(endDate.millisecondsSinceEpoch);
      query += ' AND occurred_at <= ?';
    }
    query += ' ORDER BY occurred_at DESC';
    final rows = await _store.executor.runSelect(query, params);
    return rows
        .map(
          (r) => PdfTransactionRow(
            title: '${r['title'] ?? ''}',
            category: '${r['category'] ?? ''}',
            amount: _asDouble(r['amount']),
            occurredAt: r['occurred_at'] as int?,
          ),
        )
        .toList();
  }

  Future<List<PdfIncomeRow>> _fetchIncomes({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <Object?>[];
    var query = 'SELECT title, amount, received_at FROM incomes WHERE 1=1';
    if (startDate != null) {
      params.add(startDate.millisecondsSinceEpoch);
      query += ' AND received_at >= ?';
    }
    if (endDate != null) {
      params.add(endDate.millisecondsSinceEpoch);
      query += ' AND received_at <= ?';
    }
    query += ' ORDER BY received_at DESC';
    final rows = await _store.executor.runSelect(query, params);
    return rows
        .map(
          (r) => PdfIncomeRow(
            title: '${r['title'] ?? ''}',
            amount: _asDouble(r['amount']),
            receivedAt: r['received_at'] as int?,
          ),
        )
        .toList();
  }

  double _asDouble(Object? value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  Future<List<_ExportChunk>> _buildScopedExports(
    ExportScope scope, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final chunks = <_ExportChunk>[];
    if (scope == ExportScope.all || scope == ExportScope.expenses) {
      final params = <Object?>[];
      var query =
          'SELECT id, title, category, amount, occurred_at, source FROM transactions';
      query += _dateWhere('occurred_at', startDate, endDate, params);
      query += ' ORDER BY occurred_at DESC';
      chunks.add(
        await _buildChunk(
          name: 'expenses',
          query: query,
          headers: const [
            'id',
            'title',
            'category',
            'amount',
            'occurred_at',
            'source',
          ],
          params: params,
        ),
      );
    }
    if (scope == ExportScope.all || scope == ExportScope.incomes) {
      final params = <Object?>[];
      var query = 'SELECT id, title, amount, received_at, source FROM incomes';
      query += _dateWhere('received_at', startDate, endDate, params);
      query += ' ORDER BY received_at DESC';
      chunks.add(
        await _buildChunk(
          name: 'incomes',
          query: query,
          headers: const ['id', 'title', 'amount', 'received_at', 'source'],
          params: params,
        ),
      );
    }
    if (scope == ExportScope.all || scope == ExportScope.tasks) {
      final params = <Object?>[];
      var query =
          'SELECT id, title, description, completed, due_at, priority FROM tasks';
      query += _dateWhere('due_at', startDate, endDate, params);
      query += ' ORDER BY id DESC';
      chunks.add(
        await _buildChunk(
          name: 'tasks',
          query: query,
          headers: const [
            'id',
            'title',
            'description',
            'completed',
            'due_at',
            'priority',
          ],
          params: params,
        ),
      );
    }
    if (scope == ExportScope.all || scope == ExportScope.events) {
      final params = <Object?>[];
      var query = 'SELECT id, title, start_at, end_at, note FROM events';
      query += _dateWhere('start_at', startDate, endDate, params);
      query += ' ORDER BY start_at DESC';
      chunks.add(
        await _buildChunk(
          name: 'events',
          query: query,
          headers: const ['id', 'title', 'start_at', 'end_at', 'note'],
          params: params,
        ),
      );
    }
    if (scope == ExportScope.all || scope == ExportScope.budgets) {
      chunks.add(
        await _buildChunk(
          name: 'budgets',
          query:
              'SELECT id, category, monthly_limit FROM budgets ORDER BY category',
          headers: const ['id', 'category', 'monthly_limit'],
        ),
      );
    }
    if (scope == ExportScope.all || scope == ExportScope.recurring) {
      chunks.add(
        await _buildChunk(
          name: 'recurring_templates',
          query:
              'SELECT id, kind, title, description, category, amount, priority, cadence, next_run_at, enabled FROM recurring_templates ORDER BY id DESC',
          headers: const [
            'id',
            'kind',
            'title',
            'description',
            'category',
            'amount',
            'priority',
            'cadence',
            'next_run_at',
            'enabled',
          ],
        ),
      );
    }
    return chunks;
  }

  String _dateWhere(
    String column,
    DateTime? start,
    DateTime? end,
    List<Object?> params,
  ) {
    final conditions = <String>[];
    if (start != null) {
      conditions.add('$column >= ?');
      params.add(start.millisecondsSinceEpoch);
    }
    if (end != null) {
      conditions.add('$column <= ?');
      params.add(end.millisecondsSinceEpoch);
    }
    if (conditions.isEmpty) return '';
    return ' WHERE ${conditions.join(' AND ')}';
  }

  String _dateTag({DateTime? startDate, DateTime? endDate}) {
    final parts = <String>[];
    if (startDate != null) {
      parts.add(
        '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}',
      );
    }
    if (endDate != null) {
      parts.add(
        '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}',
      );
    }
    if (parts.isEmpty) return '';
    return '_${parts.join('_to_')}';
  }

  Future<_ExportChunk> _buildChunk({
    required String name,
    required String query,
    required List<String> headers,
    List<Object?> params = const [],
  }) async {
    final rows = await _store.executor.runSelect(query, params);
    final values = rows
        .map((row) => headers.map((header) => row[header]).toList())
        .toList();
    return _ExportChunk(
      name: name,
      csv: _csvBuilder.build(headers: headers, rows: values),
      rows: rows.length,
    );
  }
}

class _ExportChunk {
  const _ExportChunk({
    required this.name,
    required this.csv,
    required this.rows,
  });

  final String name;
  final String csv;
  final int rows;
}
