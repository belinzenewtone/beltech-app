// Promotional suffixes Safaricom appends to some transaction SMS.
// Strip from the first match to end-of-string before any other processing.
//
// Groups cover known Safaricom promo variants:
//   • Reward/loyalty tails ("earn rewards", "redeem points")
//   • App / web marketing tails ("visit m-pesa.com", "on Google Play")
//   • Balance check CTAs ("dial *234#")
//   • Fuliza / Hustler Fund upsell tails
//   • Step-by-step guide references
//   • KYC / verification nags ("update your details")
final _promoTailPattern = RegExp(
  r'\s*(?:'
  r'earn\b[^.]*?rewards'
  r'|redeem\s+(?:your\s+)?points'
  r'|visit\s+m-?pesa\.?com'
  r'|get\s+more\s+at\s+m-?pesa'
  r'|step\s+by\s+step'
  r'|dial\s*\*\d+[*#][^\s]*\s+to\s+(?:access|pay|check|borrow|repay|register)'
  r'|available\s+on\s+google\s+play'
  r'|download\s+(?:the\s+)?m-?pesa\s+app'
  r'|for\s+(?:more\s+)?(?:info|details|help)\s+(?:dial|call|visit)'
  r'|to\s+get\s+(?:more\s+)?time\s+to\s+pay'
  r'|hustler\s+fund\s+is'
  r'|connect\s+your\s+(?:card|bank)'
  r'|shop\s+&\s+pay\s+using'
  r'|update\s+your\s+(?:m-?pesa\s+)?details'
  r'|(?:you\s+can\s+)?borrow\s+up\s+to'
  r').*$',
  caseSensitive: false,
);

String normalizeParserText(String message) => message
    .trim()
    // Strip promotional suffixes before all other processing.
    .replaceAll(_promoTailPattern, '')
    // Normalize non-breaking spaces to regular spaces.
    .replaceAll('\u00A0', ' ')
    // Remove zero-width chars entirely to avoid splitting tokens.
    .replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '')
    // Normalize curly quotes and dashes used by some SMS gateways.
    .replaceAll('\u2019', "'")
    .replaceAll('\u2018', "'")
    .replaceAll('\u201C', '"')
    .replaceAll('\u201D', '"')
    .replaceAll('\u2013', '-')
    .replaceAll('\u2014', '-')
    // Collapse any run of whitespace (including newlines) to a single space.
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String titleCaseWords(String text) => text
    .split(' ')
    .map(
      (part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
    )
    .join(' ');

bool looksLikeMpesaMessage(String message) {
  final lower = message.toLowerCase();
  // Word-boundary anchor; require at least one digit and one letter so plain
  // words and pure-digit strings (phone numbers) do not false-positive.
  final hasTxCode = RegExp(
    r'\b(?=[a-z0-9]*\d)(?=[a-z0-9]*[a-z])[a-z0-9]{9,10}\b',
    caseSensitive: false,
  ).hasMatch(message.trim());
  final hasAmount = lower.contains('ksh') || lower.contains('kes');
  return lower.contains('mpesa') ||
      lower.contains('m-pesa') ||
      (lower.contains('confirmed') && (hasAmount || hasTxCode)) ||
      (hasAmount &&
          RegExp(
            r'\b(you have received|sent to|paid to|received from)\b',
            caseSensitive: false,
          ).hasMatch(message));
}

// ── Date parsing ──────────────────────────────────────────────────────────────

// Pattern A: "on DD/MM/YY[YY] at HH:MM [am/pm]" — the canonical M-Pesa format.
//            "on" is optional; 2- or 4-digit year; 12h or 24h time.
final _datePatternSlashAt = RegExp(
  r'(?:on\s+)?(\d{1,2}/\d{1,2}/\d{2,4})\s+at\s+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:am|pm)?)',
  caseSensitive: false,
);

// Pattern B: "DD/MM/YY[YY] HH:MM [am/pm]" — slash date without "at".
final _datePatternSlashSpace = RegExp(
  r'(\d{1,2}/\d{1,2}/\d{2,4})[,\s]+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:am|pm)?)',
  caseSensitive: false,
);

// Pattern C: "14 Jul 2026 14:30" — day + short/long month name + year.
final _datePatternMonthName = RegExp(
  r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})\s+(\d{1,2}:\d{2}(?::\d{2})?(?:\s*[AaPp][Mm])?)',
);

// Pattern D: "2026-07-14 14:30" or "2026-07-14T14:30".
final _datePatternIso = RegExp(
  r'(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}:\d{2}(?::\d{2})?)',
);

const _monthNames = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// Parses an M-Pesa date/time from [message] trying 4 format variants.
///
/// Returns [fallback] (instead of null) when the date cannot be parsed, so
/// callers get the SMS-arrival timestamp rather than `DateTime.now()` guesses.
/// Returns [fallback] also when the parsed date is > 24 h in the future
/// relative to [fallback] (or wall-clock when [fallback] is null).
DateTime? parseMpesaDateTime(String message, {DateTime? fallback}) {
  final parsed = _tryParseDate(message);
  if (parsed == null) return fallback;
  final ref = fallback ?? DateTime.now();
  if (parsed.isAfter(ref.add(const Duration(hours: 24)))) return fallback;
  return parsed;
}

DateTime? _tryParseDate(String message) {
  final mA = _datePatternSlashAt.firstMatch(message);
  if (mA != null) {
    return _parseSlashDateTime(mA.group(1)!, mA.group(2)!.trim());
  }
  final mB = _datePatternSlashSpace.firstMatch(message);
  if (mB != null) {
    return _parseSlashDateTime(mB.group(1)!, mB.group(2)!.trim());
  }
  final mC = _datePatternMonthName.firstMatch(message);
  if (mC != null) {
    final day = int.tryParse(mC.group(1)!);
    final month = _monthNames[mC.group(2)!.toLowerCase().substring(0, 3)];
    var year = int.tryParse(mC.group(3)!);
    if (day != null && month != null && year != null) {
      if (year < 100) year += 2000;
      return _parseTimeIntoDate(year, month, day, mC.group(4)!.trim());
    }
  }
  final mD = _datePatternIso.firstMatch(message);
  if (mD != null) {
    final year = int.tryParse(mD.group(1)!);
    final month = int.tryParse(mD.group(2)!);
    final day = int.tryParse(mD.group(3)!);
    if (year != null && month != null && day != null) {
      return _parseTimeIntoDate(year, month, day, mD.group(4)!.trim());
    }
  }
  return null;
}

DateTime? _parseSlashDateTime(String datePart, String timePart) {
  final parts = datePart.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  var year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  if (year < 100) year += 2000;
  return _parseTimeIntoDate(year, month, day, timePart);
}

final _re12h = RegExp(
  r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(am|pm)$',
  caseSensitive: false,
);
final _re24h = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$');

DateTime? _parseTimeIntoDate(int year, int month, int day, String timePart) {
  final m12 = _re12h.firstMatch(timePart);
  if (m12 != null) {
    var hour = int.parse(m12.group(1)!);
    final minute = int.parse(m12.group(2)!);
    final meridiem = m12.group(3)!.toLowerCase();
    if (minute > 59 || hour < 1 || hour > 12) return null;
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    return _strictDateTime(year, month, day, hour, minute);
  }
  final m24 = _re24h.firstMatch(timePart);
  if (m24 != null) {
    final hour = int.parse(m24.group(1)!);
    final minute = int.parse(m24.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return _strictDateTime(year, month, day, hour, minute);
  }
  return null;
}

DateTime? _strictDateTime(int year, int month, int day, int hour, int minute) {
  final parsed = DateTime(year, month, day, hour, minute);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}
