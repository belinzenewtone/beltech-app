// Fuliza pattern analysis from the real SMS dump.
// Run: dart run tool/fuliza_analysis.dart build/sms_inbox_dump.txt

import 'dart:io';

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'build/sms_inbox_dump.txt';
  final lines = File(path).readAsLinesSync();

  // Reassemble messages (multi-line bodies).
  final messages = <String>[];
  for (final line in lines) {
    if (line.startsWith('Row: ')) {
      final bodyStart = line.indexOf('body=') + 5;
      final bodyEnd = line.lastIndexOf(', date=');
      final body = bodyStart < bodyEnd
          ? line.substring(bodyStart, bodyEnd)
          : '';
      messages.add(body);
    } else if (messages.isNotEmpty && line.trim().isNotEmpty) {
      messages[messages.length - 1] =
          '${messages[messages.length - 1]}\n${line.trim()}';
    }
  }

  final fuliza = messages.where((m) => m.toLowerCase().contains('fuliza')).toList();
  stdout.writeln('Total messages: ${messages.length}, Fuliza messages: ${fuliza.length}');

  final categories = <String, int>{};
  for (final m in fuliza) {
    final lower = m.toLowerCase();
    final cat = _classify(lower);
    categories[cat] = (categories[cat] ?? 0) + 1;
  }
  final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sorted) {
    stdout.writeln('${e.key}: ${e.value}');
  }

  // Print a few representative samples per category.
  stdout.writeln('\n--- Samples ---');
  for (final e in sorted) {
    final samples = fuliza.where((m) => _classify(m.toLowerCase()) == e.key).take(3).toList();
    stdout.writeln('\n[$e.key]');
    for (final s in samples) {
      stdout.writeln('  ${s.replaceAll('\n', ' ')}');
    }
  }
}

String _classify(String lower) {
  if (lower.contains('has been used to') && lower.contains('fully pay')) return 'repayment_full';
  if (lower.contains('has been used to') && lower.contains('partially pay')) return 'repayment_partial';
  if (lower.contains('fuliza m-pesa amount is') && lower.contains('access fee charged')) {
    return 'charge_notice';
  }
  if (lower.contains('added to your m-pesa') || lower.contains('amount credited')) {
    return 'draw';
  }
  if (lower.contains('failed') || lower.contains('insufficient')) return 'failed';
  if (lower.contains('outstanding amount')) return 'outstanding_notice';
  if (lower.contains('your fuliza m-pesa limit is')) return 'limit_notice';
  if (lower.contains('dial') && lower.contains('fuliza')) return 'promo_optin';
  return 'other';
}
