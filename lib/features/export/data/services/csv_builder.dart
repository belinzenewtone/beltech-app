class CsvBuilder {
  const CsvBuilder();

  String build({
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(','));
    }
    return buffer.toString();
  }

  String _escape(Object? value) {
    final raw = '${value ?? ''}';
    final escaped = raw.replaceAll('"', '""');
    return '"$escaped"';
  }
}
