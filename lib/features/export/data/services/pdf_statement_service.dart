import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfStatementService {
  const PdfStatementService();

  Future<String> generate({
    required List<PdfTransactionRow> transactions,
    required List<PdfIncomeRow> incomes,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final amountFmt = NumberFormat('#,##0.00');

    final totalIncome = incomes.fold<double>(0, (s, i) => s + i.amount);
    final totalExpenses = transactions.fold<double>(0, (s, t) => s + t.amount);
    final netBalance = totalIncome - totalExpenses;
    final allRows = <_PdfRow>[];

    for (final t in transactions) {
      allRows.add(
        _PdfRow(
          date: _formatMillis(t.occurredAt, dateFmt),
          title: t.title,
          category: t.category,
          amount: '-KES ${amountFmt.format(t.amount)}',
          isExpense: true,
        ),
      );
    }
    for (final i in incomes) {
      allRows.add(
        _PdfRow(
          date: _formatMillis(i.receivedAt, dateFmt),
          title: i.title,
          category: 'Income',
          amount: '+KES ${amountFmt.format(i.amount)}',
          isExpense: false,
        ),
      );
    }
    allRows.sort((a, b) => b.date.compareTo(a.date));

    final categoryMap = <String, _CategorySummary>{};
    for (final t in transactions) {
      final key = t.category.isEmpty ? 'Uncategorized' : t.category;
      categoryMap.putIfAbsent(key, () => _CategorySummary(category: key));
      categoryMap[key]!.total += t.amount;
      categoryMap[key]!.count++;
    }
    final categories = categoryMap.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final pageFormat = PdfPageFormat.a4;
    const tableHeaders = ['Date', 'Title', 'Category', 'Amount'];

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            _buildHeader(dateFmt, now),
            pw.SizedBox(height: 8),
            if (startDate != null || endDate != null)
              _buildDateRange(startDate, endDate, dateFmt),
            pw.SizedBox(height: 16),
            _buildSummaryTable(
              totalIncome,
              totalExpenses,
              netBalance,
              transactions.length + incomes.length,
              amountFmt,
            ),
            pw.SizedBox(height: 16),
            if (categories.isNotEmpty) ...[
              pw.Header(text: 'Category Breakdown', level: 1),
              pw.SizedBox(height: 6),
              _buildCategoryTable(categories, amountFmt),
              pw.SizedBox(height: 16),
            ],
            pw.Header(text: 'Transaction List', level: 1),
            pw.SizedBox(height: 6),
            _buildTransactionTable(allRows, tableHeaders),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _buildFooter(now, dateFmt),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${dir.path}${Platform.pathSeparator}beltech_statement_$stamp.pdf',
    );
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  pw.Widget _buildHeader(DateFormat fmt, DateTime now) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.teal, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BELTECH',
                style: const pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Financial Statement',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            fmt.format(now),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDateRange(DateTime? start, DateTime? end, DateFormat fmt) {
    String range;
    if (start != null && end != null) {
      range = '${fmt.format(start)}  -  ${fmt.format(end)}';
    } else if (start != null) {
      range = 'From ${fmt.format(start)}';
    } else if (end != null) {
      range = 'Until ${fmt.format(end)}';
    } else {
      range = 'All time';
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        'Period: $range',
        style: const pw.TextStyle(
          fontSize: 11,
          color: PdfColors.teal,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryTable(
    double totalIncome,
    double totalExpenses,
    double netBalance,
    int count,
    NumberFormat amountFmt,
  ) {
    const headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.teal,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            child: pw.Text('Summary', style: headerStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                _summaryRow(
                  'Total Income',
                  '+KES ${amountFmt.format(totalIncome)}',
                  PdfColors.green700,
                ),
                _summaryRow(
                  'Total Expenses',
                  '-KES ${amountFmt.format(totalExpenses)}',
                  PdfColors.red700,
                ),
                _summaryRow(
                  'Net Balance',
                  'KES ${amountFmt.format(netBalance)}',
                  netBalance >= 0 ? PdfColors.green900 : PdfColors.red900,
                ),
                _summaryRow(
                  'Transaction Count',
                  count.toString(),
                  PdfColors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.TableRow _summaryRow(String label, String value, PdfColor valueColor) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCategoryTable(
    List<_CategorySummary> categories,
    NumberFormat amountFmt,
  ) {
    const headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    const cellStyle = pw.TextStyle(fontSize: 9);

    return pw.TableHelper.fromTextArray(
      headerStyle: headerStyle,
      cellStyle: cellStyle,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Category', 'Total (KES)', 'Transactions'],
      data: categories
          .map(
            (c) => [c.category, amountFmt.format(c.total), c.count.toString()],
          )
          .toList(),
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
      },
    );
  }

  pw.Widget _buildTransactionTable(List<_PdfRow> rows, List<String> headers) {
    if (rows.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Text(
          'No transactions for the selected period.',
          style: const pw.TextStyle(
            fontSize: 10,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey500,
          ),
        ),
      );
    }

    const headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    const cellStyle = pw.TextStyle(fontSize: 9);

    return pw.TableHelper.fromTextArray(
      headerStyle: headerStyle,
      cellStyle: cellStyle,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headers: headers,
      data: rows.map((r) => [r.date, r.title, r.category, r.amount]).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(70),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(90),
      },
    );
  }

  pw.Widget _buildFooter(DateTime now, DateFormat fmt) {
    return pw.Center(
      child: pw.Text(
        'Generated by BELTECH on ${fmt.format(now)}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }

  String _formatMillis(int? millis, DateFormat fmt) {
    if (millis == null || millis == 0) return '-';
    return fmt.format(DateTime.fromMillisecondsSinceEpoch(millis));
  }
}

class PdfTransactionRow {
  const PdfTransactionRow({
    required this.title,
    required this.category,
    required this.amount,
    required this.occurredAt,
  });

  final String title;
  final String category;
  final double amount;
  final int? occurredAt;
}

class PdfIncomeRow {
  const PdfIncomeRow({
    required this.title,
    required this.amount,
    required this.receivedAt,
  });

  final String title;
  final double amount;
  final int? receivedAt;
}

class _CategorySummary {
  _CategorySummary({required this.category});

  final String category;
  double total = 0;
  int count = 0;
}

class _PdfRow {
  const _PdfRow({
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
    required this.isExpense,
  });

  final String date;
  final String title;
  final String category;
  final String amount;
  final bool isExpense;
}
