// Standalone SMS analysis script for parser improvement.
//
// Parses a `content query --uri content://sms/inbox` dump, classifies each
// message's institution, runs the Dart parser over the financial ones, and
// prints a report: institution counts, parse outcomes, rejected messages, and
// quarantined examples — the raw data to improve the algorithm.
//
// Run:  dart run tool/sms_analysis.dart build/sms_inbox_dump.txt

import 'dart:io';

import 'package:beltech/features/expenses/data/services/generic_bank_parser.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_filters.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_detection.dart';

class SmsRecord {
  SmsRecord({required this.id, required this.address, required this.body, required this.date});
  final int id;
  final String address;
  String body;
  final DateTime date;
}

List<SmsRecord> parseDump(String path) {
  final lines = File(path).readAsLinesSync();
  final merged = <SmsRecord>[];
  for (final line in lines) {
    if (line.startsWith('Row: ')) {
      final idMatch = RegExp(r'_id=(\d+)').firstMatch(line);
      final addrMatch = RegExp(r'address=(.*?), body=').firstMatch(line);
      final dateMatch = RegExp(r'date=(\d+)').firstMatch(line);
      if (idMatch == null || addrMatch == null || dateMatch == null) continue;
      final id = int.parse(idMatch.group(1)!);
      final address = addrMatch.group(1)!;
      final date = DateTime.fromMillisecondsSinceEpoch(
        int.parse(dateMatch.group(1)!),
      );
      final bodyStart = line.indexOf('body=') + 5;
      final bodyEnd = line.lastIndexOf(', date=');
      final body = bodyStart < bodyEnd
          ? line.substring(bodyStart, bodyEnd)
          : '';
      merged.add(SmsRecord(id: id, address: address, body: body, date: date));
    } else if (merged.isNotEmpty && line.trim().isNotEmpty) {
      // Continuation of the previous message's body.
      merged.last.body = '${merged.last.body}\n${line.trim()}';
    }
  }
  return merged;
}

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'build/sms_inbox_dump.txt';
  final records = parseDump(path);
  stdout.writeln('Parsed ${records.length} SMS records from $path');

  const parser = MpesaParserService();

  // Classify financial messages + institution.
  final financial = <SmsRecord>[];
  final counts = <String, int>{};
  for (final r in records) {
    final body = r.body.trim();
    if (body.isEmpty) continue;
    final lower = body.toLowerCase();
    final isMpesa =
        r.address.toLowerCase().contains('mpesa') ||
        lower.contains('m-pesa') ||
        lower.contains('mpesa');
    final isBank = GenericBankParser.looksLikeBankSms(body, sender: r.address);
    if (!isMpesa && !isBank) continue;
    final institution = detectInstitutionId(r.address, body);
    counts[institution] = (counts[institution] ?? 0) + 1;
    financial.add(r);
  }

  stdout.writeln('Financial messages: ${financial.length}');
  stdout.writeln('\n--- Institution counts ---');
  final sortedCounts = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sortedCounts) {
    stdout.writeln('${institutionDisplayName(e.key)}: ${e.value}');
  }

  // Run parser.
  final outcomes = <String, int>{};
  final rejected = <SmsRecord>[];
  final quarantined = <SmsRecord>[];
  for (final r in financial) {
    final body = r.body.trim();
    final candidate = parser.parseSingleDetailed(
      body,
      sender: r.address,
      fallbackOccurredAt: r.date,
    ) ??
        // Only fall back when the message isn't a known-ignore — otherwise the
        // prepended "Confirmed" resurrects failed/balance notices as
        // quarantined rows (mirrors the pipeline's guarded fallback).
        (!shouldIgnoreMpesaSms(normalizeParserText(body))
            ? parser.parseSingleDetailed(
                'UNKNOWN Confirmed. Ksh0.00 $body',
                sender: r.address,
                fallbackOccurredAt: r.date,
              )
            : null);
    if (candidate == null) {
      rejected.add(r);
      continue;
    }
    final key = switch (candidate.route) {
      MpesaParseRoute.directLedger => 'direct_ledger',
      MpesaParseRoute.reviewQueue => 'review_queue',
      MpesaParseRoute.quarantine => 'quarantine',
    };
    outcomes[key] = (outcomes[key] ?? 0) + 1;
    if (candidate.route == MpesaParseRoute.quarantine) {
      quarantined.add(r);
    }
  }

  stdout.writeln('\n--- Parser outcomes ---');
  for (final e in outcomes.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
    stdout.writeln('${e.key}: ${e.value}');
  }

  stdout.writeln('\n--- Rejected (unparseable) --- count: ${rejected.length}');
  for (final r in rejected.take(80)) {
    stdout.writeln('[${r.address}] ${r.body.replaceAll('\n', ' ')}');
  }

  stdout.writeln('\n--- Quarantined (route=quarantine) --- count: ${quarantined.length}');
  // Categorize the quarantined messages by the likely reason.
  final reasonCounts = <String, int>{};
  for (final r in quarantined) {
    final lower = r.body.toLowerCase();
    final reason = _classifyQuarantine(lower);
    reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
  }
  final sortedReasons = reasonCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  stdout.writeln('--- Quarantine breakdown ---');
  for (final e in sortedReasons) {
    stdout.writeln('${e.key}: ${e.value}');
  }
  for (final r in quarantined.take(80)) {
    stdout.writeln('[${r.address}] ${r.body.replaceAll('\n', ' ')}');
  }
}

String _classifyQuarantine(String lower) {
  if (lower.contains('failed') || lower.contains('insufficient') ||
      lower.contains('wrong pin') || lower.contains('cannot') ||
      lower.contains('unable') || lower.contains('unsuccessful') ||
      lower.contains('not joined') || lower.contains('cancelled') ||
      lower.contains('incorrect')) {
    return 'failed_transaction';
  }
  if (lower.contains('confirmed.') && lower.contains('withdraw')) {
    return 'withdrawal_confirm';
  }
  if (lower.contains('balance')) {
    return 'balance_notice';
  }
  if (lower.contains('fuliza')) {
    return 'fuliza';
  }
  return 'other';
}
