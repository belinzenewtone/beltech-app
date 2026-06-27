import 'dart:io';

import 'package:beltech/data/local/drift/app_drift_store.dart';

class CsvImportPreview {
  const CsvImportPreview({
    required this.headers,
    required this.sampleRows,
    required this.totalRows,
    required this.detectedMappings,
  });

  final List<String> headers;
  final List<List<String>> sampleRows;
  final int totalRows;
  final Map<String, String> detectedMappings;
}

class CsvImportService {
  const CsvImportService();

  Future<CsvImportPreview> preview(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final rows = _parseCsv(content);
    if (rows.isEmpty) {
      throw Exception('CSV file is empty');
    }
    final headers = rows.first;
    final dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];
    final sampleRows = dataRows.take(5).toList();
    final detectedMappings = _detectMappings(headers);
    return CsvImportPreview(
      headers: headers,
      sampleRows: sampleRows,
      totalRows: dataRows.length,
      detectedMappings: detectedMappings,
    );
  }

  Future<int> import(
    String filePath,
    Map<String, String> columnMapping,
    AppDriftStore store,
  ) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final rows = _parseCsv(content);
    if (rows.isEmpty) {
      throw Exception('CSV file is empty');
    }
    final headers = rows.first;
    final dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    final colIndex = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      colIndex[headers[i]] = i;
    }

    final dateCol = columnMapping['occurred_at'];
    final titleCol = columnMapping['title'];
    final categoryCol = columnMapping['category'];
    final amountCol = columnMapping['amountKes'];
    final balanceCol = columnMapping['balanceAfterKes'];

    var imported = 0;
    for (final row in dataRows) {
      final title = _valueAt(row, colIndex, titleCol);
      final category = _valueAt(row, colIndex, categoryCol) ?? 'Other';
      final amountRaw = _valueAt(row, colIndex, amountCol);
      final dateRaw = _valueAt(row, colIndex, dateCol);
      final balanceRaw = _valueAt(row, colIndex, balanceCol);

      if (title == null || title.isEmpty) continue;
      final amountKes = double.tryParse(amountRaw ?? '0') ?? 0;
      if (amountKes <= 0 && amountRaw == null) continue;

      DateTime occurredAt = DateTime.now();
      if (dateRaw != null && dateRaw.isNotEmpty) {
        occurredAt = _parseDate(dateRaw);
      }

      double? balanceAfterKes;
      if (balanceRaw != null && balanceRaw.isNotEmpty) {
        balanceAfterKes = double.tryParse(balanceRaw);
      }

      await store.addTransaction(
        title: title,
        category: category,
        amountKes: amountKes,
        occurredAt: occurredAt,
        source: 'csv',
        balanceAfterKes: balanceAfterKes,
      );
      imported++;
    }

    return imported;
  }

  Map<String, String> _detectMappings(List<String> headers) {
    final mapping = <String, String>{};
    final seenTargets = <String>{};

    for (final header in headers) {
      final normalized = header.trim().toLowerCase();
      String? target;

      if (seenTargets.contains('occurred_at') &&
          seenTargets.contains('title') &&
          seenTargets.contains('category') &&
          seenTargets.contains('amountKes') &&
          seenTargets.contains('balanceAfterKes')) {
        break;
      }

      if (!seenTargets.contains('occurred_at') && _isDateColumn(normalized)) {
        target = 'occurred_at';
      } else if (!seenTargets.contains('title') && _isTitleColumn(normalized)) {
        target = 'title';
      } else if (!seenTargets.contains('category') &&
          _isCategoryColumn(normalized)) {
        target = 'category';
      } else if (!seenTargets.contains('amountKes') &&
          _isAmountColumn(normalized)) {
        target = 'amountKes';
      } else if (!seenTargets.contains('balanceAfterKes') &&
          _isBalanceColumn(normalized)) {
        target = 'balanceAfterKes';
      }

      if (target != null) {
        mapping[header] = target;
        seenTargets.add(target);
      }
    }

    return mapping;
  }

  bool _isDateColumn(String normalized) {
    const patterns = [
      'date',
      'occurred',
      'occurred_at',
      'occurredat',
      'created',
      'timestamp',
      'time',
      'datetime',
      'date_time',
      'posting date',
      'transaction date',
      'txn date',
      'tx_date',
      'txdate',
    ];
    return patterns.any((p) => normalized == p || normalized.contains(p));
  }

  bool _isTitleColumn(String normalized) {
    const patterns = [
      'description',
      'desc',
      'title',
      'name',
      'narration',
      'narrative',
      'details',
      'detail',
      'memo',
      'note',
      'notes',
      'particulars',
      'payee',
      'merchant',
      'recipient',
      'sender',
    ];
    return patterns.any((p) => normalized == p || normalized.contains(p));
  }

  bool _isCategoryColumn(String normalized) {
    const patterns = ['category', 'cat', 'type', 'group', 'tag', 'class'];
    return patterns.any((p) => normalized == p || normalized.contains(p));
  }

  bool _isAmountColumn(String normalized) {
    const patterns = [
      'amount',
      'kes',
      'value',
      'price',
      'cost',
      'sum',
      'total',
      'debit',
      'credit',
      'withdrawal',
      'deposit',
      'paid',
      'paid out',
      'money out',
      'money in',
      'transaction amount',
    ];
    return patterns.any((p) => normalized == p || normalized.contains(p));
  }

  bool _isBalanceColumn(String normalized) {
    const patterns = [
      'balance',
      'bal',
      'balance_after',
      'balanceafter',
      'balance after',
      'running balance',
      'closing balance',
      'available balance',
    ];
    return patterns.any((p) => normalized == p || normalized.contains(p));
  }

  String? _valueAt(
    List<String> row,
    Map<String, int> colIndex,
    String? columnName,
  ) {
    if (columnName == null) return null;
    final idx = colIndex[columnName];
    if (idx == null || idx >= row.length) return null;
    return row[idx].trim();
  }

  DateTime _parseDate(String raw) {
    final trimmed = raw.trim();
    final formats = [
      // yyyy-MM-dd HH:mm:ss
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2}):(\d{2})$'),
      // yyyy-MM-dd HH:mm
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})$'),
      // yyyy-MM-dd
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'),
      // dd/MM/yyyy HH:mm:ss
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})$'),
      // dd/MM/yyyy HH:mm
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})$'),
      // dd/MM/yyyy
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'),
      // MM/dd/yyyy HH:mm:ss
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})$'),
      // MM/dd/yyyy
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'),
      // dd-MM-yyyy
      RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$'),
      // yyyy/MM/dd
      RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$'),
    ];

    // Try dd/MM/yyyy first (common in Kenya/UK), then MM/dd/yyyy
    final ddMmYyyy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final match = ddMmYyyy.firstMatch(trimmed);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      if (day <= 31 && month <= 12) {
        return DateTime(year, month, day);
      }
    }

    for (final fmt in formats) {
      final m = fmt.firstMatch(trimmed);
      if (m == null) continue;
      try {
        final g1 = int.parse(m.group(1)!);
        final g2 = int.parse(m.group(2)!);
        final g3 = int.parse(m.group(3)!);
        final h = m.group(4) != null ? int.parse(m.group(4)!) : 0;
        final min = m.group(5) != null ? int.parse(m.group(5)!) : 0;
        final sec = m.group(6) != null ? int.parse(m.group(6)!) : 0;

        if (fmt.pattern.startsWith(r'^(\d{1,2})/(\d{1,2})/(\d{4})')) {
          return DateTime(g3, g2, g1, h, min, sec);
        }
        return DateTime(g1, g2, g3, h, min, sec);
      } catch (_) {
        continue;
      }
    }

    final fallback = DateTime.tryParse(trimmed);
    return fallback ?? DateTime.now();
  }
}

List<List<String>> _parseCsv(String content) {
  final rows = <List<String>>[];
  final currentRow = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < content.length; i++) {
    final ch = content[i];

    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < content.length && content[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(ch);
      }
    } else {
      if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        currentRow.add(field.toString().trim());
        field.clear();
      } else if (ch == '\n') {
        currentRow.add(field.toString().trim());
        field.clear();
        _addNonEmptyRow(rows, currentRow);
        currentRow.clear();
      } else if (ch == '\r') {
        if (i + 1 < content.length && content[i + 1] == '\n') {
          currentRow.add(field.toString().trim());
          field.clear();
          _addNonEmptyRow(rows, currentRow);
          currentRow.clear();
          i++;
        } else {
          currentRow.add(field.toString().trim());
          field.clear();
          _addNonEmptyRow(rows, currentRow);
          currentRow.clear();
        }
      } else {
        field.write(ch);
      }
    }
  }

  currentRow.add(field.toString().trim());
  _addNonEmptyRow(rows, currentRow);

  return rows;
}

void _addNonEmptyRow(List<List<String>> rows, List<String> row) {
  if (row.isNotEmpty && !(row.length == 1 && row.first.isEmpty)) {
    rows.add(List<String>.from(row));
  }
}
