String normalizeParserText(String message) => message
    .trim()
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
    // Safaricom gateway artefacts: strip byte-order marks and soft hyphens.
    .replaceAll('\uFEFF', '')
    .replaceAll('\u00AD', '')
    // Normalize "M-PESA" variants (M\u2011PESA with non-breaking hyphen, M.PESA).
    .replaceAll(RegExp(r'M[\u2011\u2012\u2010.]PESA', caseSensitive: false), 'M-PESA')
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
  final hasTxCode = RegExp(
    r'(?<![a-z0-9])[a-z0-9]{10}(?![a-z0-9])',
    caseSensitive: false,
  ).hasMatch(message.trim());
  final hasAmount = lower.contains('ksh') || lower.contains('kes');
  // Swahili M-Pesa keywords used by Safaricom in KE locale.
  final hasSwahiliKw =
      lower.contains('umetumwa') ||
      lower.contains('umepokelewa') ||
      lower.contains('imethibitishwa') ||
      lower.contains('salio lako');
  return lower.contains('mpesa') ||
      lower.contains('m-pesa') ||
      hasSwahiliKw ||
      (lower.contains('confirmed') && (hasAmount || hasTxCode)) ||
      (hasAmount &&
          RegExp(
            r'\b(you have received|sent to|paid to|received from)\b',
            caseSensitive: false,
          ).hasMatch(message));
}

// Month abbreviations used in some M-Pesa message variants.
const _monthAbbr = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

DateTime? parseMpesaDateTime(String message, RegExp dateTimePattern) {
  // Primary pattern: "on D/M/YY at H:MM AM/PM" or "on D/M/YYYY at H:MM"
  final match = dateTimePattern.firstMatch(message);
  if (match != null) {
    final parsed = _parseDateTimeParts(
      datePart: match.group(1)!,
      timePart: match.group(2)!,
      separator: '/',
    );
    if (parsed != null) return parsed;
  }

  // Extended format 1: dot-separated date "on D.M.YY at …"
  final dotMatch = RegExp(
    r'on\s+(\d{1,2}\.\d{1,2}\.\d{2,4})\s+at\s+(\d{1,2}:\d{2}\s?(?:am|pm)?)',
    caseSensitive: false,
  ).firstMatch(message);
  if (dotMatch != null) {
    final parsed = _parseDateTimeParts(
      datePart: dotMatch.group(1)!,
      timePart: dotMatch.group(2)!,
      separator: '.',
    );
    if (parsed != null) return parsed;
  }

  // Extended format 2: text-month "on D Jan 2026 at …"
  final textMonthMatch = RegExp(
    r'on\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{2,4})\s+at\s+(\d{1,2}:\d{2}\s?(?:am|pm)?)',
    caseSensitive: false,
  ).firstMatch(message);
  if (textMonthMatch != null) {
    final day = int.tryParse(textMonthMatch.group(1)!);
    final month = _monthAbbr[textMonthMatch.group(2)!.toLowerCase()];
    var year = int.tryParse(textMonthMatch.group(3)!);
    if (day != null && month != null && year != null) {
      if (year < 100) year += 2000;
      final time = _parseTimePart(textMonthMatch.group(4)!.trim());
      if (time != null) {
        return _guardFutureDate(_strictDateTime(year, month, day, time.$1, time.$2));
      }
    }
  }

  return null;
}

DateTime? _parseDateTimeParts({
  required String datePart,
  required String timePart,
  required String separator,
}) {
  final parts = datePart.split(separator);
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  var year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  if (year < 100) year += 2000;
  final time = _parseTimePart(timePart.trim());
  if (time == null) return null;
  return _guardFutureDate(_strictDateTime(year, month, day, time.$1, time.$2));
}

(int, int)? _parseTimePart(String time) {
  final twelveHour = RegExp(
    r'^(\d{1,2}):(\d{2})\s?(am|pm)$',
    caseSensitive: false,
  ).firstMatch(time);
  if (twelveHour != null) {
    var hour = int.parse(twelveHour.group(1)!);
    final minute = int.parse(twelveHour.group(2)!);
    final meridiem = twelveHour.group(3)!.toLowerCase();
    if (minute > 59 || hour < 1 || hour > 12) return null;
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    return (hour, minute);
  }
  final twentyFour = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(time);
  if (twentyFour != null) {
    final hour = int.parse(twentyFour.group(1)!);
    final minute = int.parse(twentyFour.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }
  return null;
}

// Future-date guard: reject dates more than 24 hours in the future.
DateTime? _guardFutureDate(DateTime? dt) {
  if (dt == null) return null;
  if (dt.isAfter(DateTime.now().add(const Duration(hours: 24)))) return null;
  return dt;
}

DateTime? _strictDateTime(int year, int month, int day, int hour, int minute) {
  final parsed = DateTime(year, month, day, hour, minute);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}
