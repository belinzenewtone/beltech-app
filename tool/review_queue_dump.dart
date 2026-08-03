// One-off: print all review-queue items from the SMS dump.
// Run: dart run tool/review_queue_dump.dart build/sms_inbox_dump.txt

import 'dart:io';

import 'package:beltech/features/expenses/data/services/generic_bank_parser.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'build/sms_inbox_dump.txt';
  final lines = File(path).readAsLinesSync();

  final messages = <({String sender, String body})>[];
  for (final line in lines) {
    if (!line.startsWith('Row: ')) continue;
    final addrMatch = RegExp(r'address=(.*?), body=').firstMatch(line);
    final bodyStart = line.indexOf('body=') + 5;
    final bodyEnd = line.lastIndexOf(', date=');
    if (addrMatch == null || bodyStart < 0 || bodyEnd <= bodyStart) continue;
    messages.add((sender: addrMatch.group(1)!, body: line.substring(bodyStart, bodyEnd)));
  }

  const parser = MpesaParserService();

  final review = <({String sender, String body, String type, String reason, double amount})>[];
  final quarantine = <({String sender, String body, String reason, double amount})>[];

  for (final m in messages) {
    final body = m.body.trim();
    if (body.isEmpty) continue;
    final lower = body.toLowerCase();
    final isMpesa = m.sender.toLowerCase().contains('mpesa') ||
        lower.contains('m-pesa') || lower.contains('mpesa');
    final isBank = GenericBankParser.looksLikeBankSms(body, sender: m.sender);
    if (!isMpesa && !isBank) continue;

    final candidate = parser.parseSingleDetailed(body, sender: m.sender);
    if (candidate == null) continue;

    if (candidate.route == MpesaParseRoute.reviewQueue) {
      review.add((
        sender: m.sender,
        body: body,
        type: candidate.transactionType.name,
        reason: candidate.reason ?? '-',
        amount: candidate.amountKes,
      ));
    } else if (candidate.route == MpesaParseRoute.quarantine) {
      quarantine.add((
        sender: m.sender,
        body: body,
        reason: candidate.reason ?? '-',
        amount: candidate.amountKes,
      ));
    }
  }

  stdout.writeln('=== Review Queue: ${review.length} ===');
  for (final r in review) {
    final preview = r.body.length > 140 ? '${r.body.substring(0, 140)}…' : r.body;
    stdout.writeln('[${r.sender}] type=${r.type} amount=KES${r.amount} reason="${r.reason}"');
    stdout.writeln('  > ${preview.replaceAll('\n', ' ')}');
  }

  stdout.writeln('\n=== Quarantine: ${quarantine.length} ===');
  for (final q in quarantine) {
    final preview = q.body.length > 140 ? '${q.body.substring(0, 140)}…' : q.body;
    stdout.writeln('[${q.sender}] amount=KES${q.amount} reason="${q.reason}"');
    stdout.writeln('  > ${preview.replaceAll('\n', ' ')}');
  }
}
