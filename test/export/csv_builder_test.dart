import 'package:beltech/features/export/data/services/csv_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CsvBuilder escapes quotes and commas', () {
    const builder = CsvBuilder();
    final csv = builder.build(
      headers: const ['name', 'note'],
      rows: const [
        ['Alice', 'hello,world'],
        ['Bob', 'He said "ok"'],
      ],
    );
    expect(csv.contains('"hello,world"'), isTrue);
    expect(csv.contains('"He said ""ok"""'), isTrue);
  });
}
