import 'dart:convert';

import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';
import 'package:crypto/crypto.dart';

/// Lightweight parser for non-M-Pesa Kenyan bank SMS.
///
/// Routes recognised bank messages to the review queue (medium confidence)
/// instead of quarantine, letting the user confirm them.
class GenericBankParser {
  const GenericBankParser();

  static final _bankSenders = RegExp(
    r'\b(KCB|EQUITY|CO-?OP|NCBA|DTB|STANCHART|I&M|ABSA|FAMILY|SIDIAN|PRIME|GUARDIAN|VICTORIA|KINGDOM)\b',
    caseSensitive: false,
  );

  static final _bankKeywords = RegExp(
    r'\b(a/c|account|balance|debited|credited|withdrawal|deposit|transfer|branch|atm|cheque|kes\.?|ksh\.?)\b',
    caseSensitive: false,
  );

  // Amount patterns: Ksh/KES with optional comma-thousands, optional decimals.
  static final _amountPattern = RegExp(
    r'(?:ksh|kes)\.?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final _debitWords = RegExp(
    r'\b(debit|debited|withdrawn|paid|sent|deducted)\b',
    caseSensitive: false,
  );

  static final _creditWords = RegExp(
    r'\b(credit|credited|received|deposit|deposited)\b',
    caseSensitive: false,
  );

  /// Returns true when this message looks like a Kenyan bank SMS.
  static bool looksLikeBankSms(String message, {String? sender}) {
    final hasBankSender = sender != null && _bankSenders.hasMatch(sender);
    final body = message.toLowerCase();
    final hasKes = body.contains('kes') || body.contains('ksh');
    if (!hasKes) return false;
    if (hasBankSender) return true;
    // Body must mention a bank keyword to avoid false positives.
    return _bankSenders.hasMatch(message) && _bankKeywords.hasMatch(message);
  }

  /// Attempts to parse a bank SMS. Returns null if parsing fails.
  ParsedMpesaCandidate? tryParse(
    String message, {
    String? sender,
    DateTime? fallbackOccurredAt,
  }) {
    if (!looksLikeBankSms(message, sender: sender)) return null;

    final normalized = normalizeParserText(message);
    final amountMatch = _amountPattern.firstMatch(normalized);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    final institution = _detectInstitution(normalized, sender);
    final isDebit = _debitWords.hasMatch(normalized);
    final isCredit = _creditWords.hasMatch(normalized);

    final txType = isCredit && !isDebit
        ? MpesaTransactionType.received
        : MpesaTransactionType.sent;

    final occurredAt = _parseBankDateTime(normalized) ?? fallbackOccurredAt ?? DateTime.now();
    final title = '$institution ${isCredit && !isDebit ? 'Credit' : 'Debit'}';
    final src = sha256.convert(utf8.encode(normalized)).toString();
    final sem = sha256
        .convert(utf8.encode('bank|${institution.toLowerCase()}|$amount|${occurredAt.millisecondsSinceEpoch ~/ 60000}'))
        .toString();

    return ParsedMpesaCandidate(
      mpesaCode: 'BANK${src.substring(0, 6).toUpperCase()}',
      title: title,
      category: isCredit && !isDebit ? 'Income' : 'Other',
      amountKes: amount,
      occurredAt: occurredAt,
      rawMessage: message,
      transactionType: txType,
      confidence: MpesaConfidence.medium,
      route: MpesaParseRoute.reviewQueue,
      sourceHash: src,
      semanticHash: sem,
      counterparty: institution,
      reason: 'Bank SMS — requires review',
    );
  }

  static final _bankDatePattern = RegExp(
    r'on\s+(\d{1,2}/\d{1,2}/\d{2,4})\s+at\s+(\d{1,2}:\d{2}\s?(?:am|pm)?)',
    caseSensitive: false,
  );

  static DateTime? _parseBankDateTime(String normalized) {
    final match = _bankDatePattern.firstMatch(normalized);
    if (match == null) return null;
    final datePart = match.group(1)!.split('/');
    final timePart = match.group(2)!.trim();
    if (datePart.length != 3) return null;
    final day = int.tryParse(datePart[0]);
    final month = int.tryParse(datePart[1]);
    var year = int.tryParse(datePart[2]);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    final timeRe = RegExp(r'(\d{1,2}):(\d{2})\s?(am|pm)?', caseSensitive: false);
    final timeMatch = timeRe.firstMatch(timePart);
    if (timeMatch == null) return null;
    var hour = int.parse(timeMatch.group(1)!);
    final minute = int.parse(timeMatch.group(2)!);
    final ampm = timeMatch.group(3)?.toLowerCase();
    if (ampm == 'pm' && hour < 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;
    return DateTime(year, month, day, hour, minute);
  }

  static String _detectInstitution(String normalized, String? sender) {
    final text = '${sender ?? ''} $normalized'.toLowerCase();
    if (text.contains('equity')) return 'Equity Bank';
    if (text.contains('kcb')) return 'KCB';
    if (text.contains('co-op') || text.contains('coop') || text.contains('cooperative')) return 'Co-op Bank';
    if (text.contains('ncba')) return 'NCBA';
    if (text.contains('dtb')) return 'DTB';
    if (text.contains('stanchart') || text.contains('standard chartered')) return 'Standard Chartered';
    if (text.contains('i&m')) return 'I&M Bank';
    if (text.contains('absa')) return 'Absa';
    if (text.contains('family')) return 'Family Bank';
    if (text.contains('sidian')) return 'Sidian Bank';
    if (text.contains('prime')) return 'Prime Bank';
    return 'Bank';
  }
}
