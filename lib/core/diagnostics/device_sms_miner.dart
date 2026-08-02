import 'dart:io';

import 'package:beltech/features/expenses/data/services/generic_bank_parser.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Debug-only real-device SMS mining (Phase P7).
///
/// Runs at app startup in debug builds: reads the actual inbox, classifies
/// financial SMS, runs each through the parser, and writes a coverage report
/// to `device_sms_report.txt` in the app documents directory. Pull it with:
///   adb exec-out run-as &lt;package&gt; cat files/device_sms_report.txt
///
/// The report feeds the parser improvement loop (institution counts, parse
/// outcomes, rejected / mis-routed examples).
class DeviceSmsMiner {
  static const _maxMessages = 3000;

  static Future<void> runIfDebug() async {
    if (!kDebugMode) {
      return;
    }
    try {
      final status = await Permission.sms.status;
      if (!status.isGranted) {
        return;
      }

      final query = SmsQuery();
      // Paginate explicitly — the plugin's single shot can cap out on large
      // inboxes. Pull up to _maxMessages in chunks of 500.
      var messages = <SmsMessage>[];
      for (var start = 0; messages.length < _maxMessages; start += 500) {
        final chunk = await query.querySms(
          kinds: const [SmsQueryKind.inbox],
          start: start,
          count: 500,
        );
        if (chunk.isEmpty) {
          break;
        }
        messages.addAll(chunk);
      }
      // Dedupe by id — the pagination can overlap across chunk boundaries.
      final seenIds = <int>{};
      messages = messages.where((m) {
        final id = m.id;
        if (id == null) return true;
        return seenIds.add(id);
      }).toList();

      const parser = MpesaParserService();

      // Classify financial messages and count per institution.
      final financial = <({SmsMessage msg, String institution})>[];
      final counts = <String, int>{};
      for (final msg in messages) {
        final body = msg.body?.trim() ?? '';
        final sender = msg.address ?? '';
        if (body.isEmpty) continue;
        final lower = body.toLowerCase();
        final isMpesa =
            sender.toLowerCase().contains('mpesa') ||
            lower.contains('m-pesa') ||
            lower.contains('mpesa');
        final isBank = GenericBankParser.looksLikeBankSms(
          body,
          sender: sender,
        );
        if (!isMpesa && !isBank) continue;
        final institution = detectInstitutionId(sender, body);
        counts[institution] = (counts[institution] ?? 0) + 1;
        financial.add((msg: msg, institution: institution));
      }

      // Run the parser over every financial message.
      final outcomes = <String, int>{};
      final rejected = <({String sender, String body, String institution})>[];
      final misRouted = <({String sender, String body, String institution})>[];
      final quarantined = <({String sender, String body, String institution})>[];
      for (final entry in financial) {
        final body = entry.msg.body!;
        final sender = entry.msg.address ?? '';
        final institution = entry.institution;

        final candidate = parser.parseSingleDetailed(
          body,
          sender: sender,
          fallbackOccurredAt: entry.msg.date,
        ) ??
            parser.parseSingleDetailed(
              'UNKNOWN Confirmed. Ksh0.00 $body',
              sender: sender,
              fallbackOccurredAt: entry.msg.date,
            );

        if (candidate == null) {
          rejected.add((sender: sender, body: body, institution: institution));
          continue;
        }

        final key = switch (candidate.route) {
          MpesaParseRoute.directLedger => 'direct_ledger',
          MpesaParseRoute.reviewQueue => 'review_queue',
          MpesaParseRoute.quarantine => 'quarantine',
        };
        outcomes[key] = (outcomes[key] ?? 0) + 1;

        if (candidate.route == MpesaParseRoute.quarantine) {
          quarantined.add((
            sender: sender,
            body: body,
            institution: institution,
          ));
        }

        if (institution != 'mpesa' &&
            candidate.route != MpesaParseRoute.directLedger) {
          misRouted.add((sender: sender, body: body, institution: institution));
        }
      }

      // Build + persist the report.
      final lines = StringBuffer()
        ..writeln('=== Device SMS Mining Report ===')
        ..writeln('Scanned ${messages.length} inbox messages')
        ..writeln('Financial messages: ${financial.length}')
        ..writeln()
        ..writeln('--- Institution counts ---');
      final sortedCounts = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sortedCounts) {
        lines.writeln('${institutionDisplayName(e.key)}: ${e.value}');
      }

      lines
        ..writeln()
        ..writeln('--- Parser outcomes ---');
      for (final e in outcomes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))) {
        lines.writeln('${e.key}: ${e.value}');
      }

      lines
        ..writeln()
        ..writeln('--- Rejected (unparseable) ---')
        ..writeln('count: ${rejected.length}');
      for (final r in rejected.take(60)) {
        lines.writeln(
          '[${r.institution}] ${r.sender}: ${r.body.replaceAll('\n', ' ')}',
        );
      }

      lines
        ..writeln()
        ..writeln('--- Quarantined (parser rejected to quarantine) ---')
        ..writeln('count: ${quarantined.length}');
      for (final r in quarantined.take(60)) {
        lines.writeln(
          '[${r.institution}] ${r.sender}: ${r.body.replaceAll('\n', ' ')}',
        );
      }

      lines
        ..writeln()
        ..writeln('--- Bank/PesaLink mis-routed to review/quarantine ---')
        ..writeln('count: ${misRouted.length}');
      for (final r in misRouted.take(60)) {
        lines.writeln(
          '[${r.institution}] ${r.sender}: ${r.body.replaceAll('\n', ' ')}',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/device_sms_report.txt');
      await file.writeAsString(lines.toString());
      // ignore: avoid_print
      debugPrint('DeviceSmsMiner: report written to ${file.path}');
      // ignore: avoid_print
      debugPrint(lines.toString());
    } catch (error) {
      // ignore: avoid_print
      debugPrint('DeviceSmsMiner: failed — $error');
    }
  }
}
