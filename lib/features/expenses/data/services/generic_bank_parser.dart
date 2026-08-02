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
    r'\b(KCB|EQUITY|CO-?OP|NCBA|LOOP|DTB|STANCHART|I&M|IANDM|IMBANK|ABSA|FAMILY|SIDIAN|PRIME|GUARDIAN|VICTORIA|KINGDOM|PESALINK|IPSL|STANBIC|SBM)\w*\b',
    caseSensitive: false,
  );

  static final _bankKeywords = RegExp(
    r'\b(a/c|account|balance|debited|credited|withdrawal|deposit|transfer|branch|atm|cheque|kes\.?|ksh\.?|pesalink|till)\b',
    caseSensitive: false,
  );

  // Amount patterns: Ksh/KES with optional comma-thousands, optional decimals.
  // Handles "Ksh", "KES", "Kshs.", "KES." before the amount. The number
  // alternation is ordered so "1000" matches fully (not just "100").
  static final _amountPattern = RegExp(
    r'(?:ksh|kes)s?\.?\s*(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Equity/Eazzy format: amount BEFORE the KES marker — "50.00 KES",
  // "of 270 KES", "22000.00 KES has been successfully sent".
  static final _reversedAmountPattern = RegExp(
    r'(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)\s*(?:kes|ksh)',
    caseSensitive: false,
  );

  // OTP / verification codes — no money moved, never import.
  static final _otpPattern = RegExp(
    r'never\s+share\s+this\s+code|use\s+code\s+\d+\s+to\s+(?:send|verify)',
    caseSensitive: false,
  );

  // Card auth holds (amount 0.00) — not real transactions. Covers approved
  // and declined card authorisations: "Online transaction of KES.0.00 has been
  // approved/Declined on your card ...".
  static final _cardHoldPattern = RegExp(
    r'online\s+transaction\s+of\s+(?:kes|ksh)\.?\s*0\.?0*\s+has\s+been\s+(?:approved|declined).*?on\s+your\s+card',
    caseSensitive: false,
  );

  // Extract the most likely transaction amount, trying the reversed
  // (Equity/Eazzy) format first when present, then the standard Ksh/KES form.
  static double? _extractAmount(String normalized) {
    final reversed = _reversedAmountPattern.firstMatch(normalized);
    if (reversed != null) {
      final v = double.tryParse(reversed.group(1)!.replaceAll(',', ''));
      if (v != null && v > 0) return v;
    }
    final standard = _amountPattern.firstMatch(normalized);
    if (standard == null) return null;
    final v = double.tryParse(standard.group(1)!.replaceAll(',', ''));
    return (v != null && v > 0) ? v : null;
  }

  static final _debitWords = RegExp(
    r'\b(debit|debited|withdrawn|paid|sent|deducted|payment|purchase|bought|approved|transfered|transferred|charged)\b',
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

  /// True when a bank-sender message is a known non-transaction (OTP /
  /// verification code, zero-amount card hold) that should never be imported.
  static bool isIgnorableBankSms(String message) {
    final normalized = normalizeParserText(message);
    return _otpPattern.hasMatch(normalized) ||
        _cardHoldPattern.hasMatch(normalized);
  }

  /// Attempts to parse a bank SMS. Returns null if parsing fails.
  ParsedMpesaCandidate? tryParse(
    String message, {
    String? sender,
    DateTime? fallbackOccurredAt,
  }) {
    if (!looksLikeBankSms(message, sender: sender)) return null;

    final normalized = normalizeParserText(message);
    // OTP / verification codes and zero-amount card holds are not transactions.
    if (_otpPattern.hasMatch(normalized) || _cardHoldPattern.hasMatch(normalized)) {
      return null;
    }

    final amount = _extractAmount(normalized);
    if (amount == null) return null;

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

    // Confidence: a clean bank message (known institution + unambiguous amount
    // + explicit debit/credit verb) is high-confidence and imports directly.
    // Only genuinely ambiguous messages (no direction verb, no date) go to the
    // review queue.
    final clearDirection = (isDebit || isCredit);
    final hasDate = _parseBankDateTime(normalized) != null;
    final highConfidence = institution != 'Bank' && clearDirection && hasDate;
    final confidence = highConfidence
        ? MpesaConfidence.high
        : MpesaConfidence.medium;
    final route = highConfidence
        ? MpesaParseRoute.directLedger
        : MpesaParseRoute.reviewQueue;

    return ParsedMpesaCandidate(
      mpesaCode: 'BANK${src.substring(0, 6).toUpperCase()}',
      title: title,
      category: isCredit && !isDebit ? 'Income' : 'Other',
      amountKes: amount,
      occurredAt: occurredAt,
      rawMessage: message,
      transactionType: txType,
      confidence: confidence,
      route: route,
      sourceHash: src,
      semanticHash: sem,
      counterparty: institution,
      reason: highConfidence ? 'Bank SMS' : 'Bank SMS — requires review',
    );
  }

  static final _bankDatePattern = RegExp(
    r'(?:on\s+)?(\d{1,2}/\d{1,2}/\d{2,4}|\d{1,2}-\d{1,2}-\d{2,4}|\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})\s+(?:at\s+)?(\d{1,2}:\d{2}(?::\d{2})?\s?(?:am|pm)?)',
    caseSensitive: false,
  );

  static DateTime? _parseBankDateTime(String normalized) {
    final match = _bankDatePattern.firstMatch(normalized);
    if (match == null) return null;
    final datePart = match.group(1)!.trim();
    final timePart = match.group(2)!.trim();

    int? day, month, year;
    // Numeric d/m/yyyy or d-m-yyyy.
    final numeric = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})$').firstMatch(datePart);
    if (numeric != null) {
      day = int.tryParse(numeric.group(1)!);
      month = int.tryParse(numeric.group(2)!);
      year = int.tryParse(numeric.group(3)!);
    } else {
      // Text month: "13 Apr 2025".
      final text = RegExp(r'^(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})$').firstMatch(datePart);
      if (text != null) {
        day = int.tryParse(text.group(1)!);
        month = _monthAbbr[text.group(2)!.toLowerCase()];
        year = int.tryParse(text.group(3)!);
      }
    }
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;

    final timeRe = RegExp(r'(\d{1,2}):(\d{2})(?::\d{2})?\s?(am|pm)?', caseSensitive: false);
    final timeMatch = timeRe.firstMatch(timePart);
    if (timeMatch == null) return null;
    var hour = int.parse(timeMatch.group(1)!);
    final minute = int.parse(timeMatch.group(2)!);
    final ampm = timeMatch.group(3)?.toLowerCase();
    if (ampm == 'pm' && hour < 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;
    return DateTime(year, month, day, hour, minute);
  }

  static const _monthAbbr = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  static String _detectInstitution(String normalized, String? sender) {
    final text = '${sender ?? ''} $normalized'.toLowerCase();
    if (text.contains('loop')) return 'NCBA Loop';
    if (text.contains('equity')) return 'Equity Bank';
    if (text.contains('kcb')) return 'KCB';
    if (text.contains('co-op') || text.contains('coop') || text.contains('cooperative')) return 'Co-op Bank';
    if (text.contains('ncba')) return 'NCBA';
    if (text.contains('dtb')) return 'DTB';
    if (text.contains('stanchart') || text.contains('standard chartered')) return 'Standard Chartered';
    if (text.contains('i&m') || text.contains('iandm') || text.contains('imbank')) return 'I&M Bank';
    if (text.contains('absa')) return 'Absa';
    if (text.contains('family')) return 'Family Bank';
    if (text.contains('sidian')) return 'Sidian Bank';
    if (text.contains('prime')) return 'Prime Bank';
    if (text.contains('pesalink') || text.contains('ipsl')) return 'PesaLink';
    if (text.contains('stanbic')) return 'Stanbic';
    if (text.contains('sbm')) return 'SBM Bank';
    return 'Bank';
  }
}
