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
    r'^[a-z0-9]{10}\b',
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

DateTime? parseMpesaDateTime(String message, RegExp dateTimePattern) {
  final match = dateTimePattern.firstMatch(message);
  if (match == null) return null;
  final date = match.group(1)?.split('/');
  final time = match.group(2);
  if (date == null || date.length != 3 || time == null) return null;
  final day = int.tryParse(date[0]);
  final month = int.tryParse(date[1]);
  var year = int.tryParse(date[2]);
  if (day == null || month == null || year == null) return null;
  if (year < 100) year += 2000;
  final twelveHourTime = RegExp(
    r'^(\d{1,2}):(\d{2})\s?(am|pm)$',
    caseSensitive: false,
  ).firstMatch(time.trim());
  if (twelveHourTime != null) {
    var hour = int.parse(twelveHourTime.group(1)!);
    final minute = int.parse(twelveHourTime.group(2)!);
    final meridiem = twelveHourTime.group(3)!.toLowerCase();
    if (minute > 59 || hour < 1 || hour > 12) {
      return null;
    }
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    return _strictDateTime(year, month, day, hour, minute);
  }

  final twentyFourHourTime = RegExp(
    r'^(\d{1,2}):(\d{2})(?::\d{2})?$',
  ).firstMatch(time.trim());
  if (twentyFourHourTime == null) {
    return null;
  }
  final hour = int.parse(twentyFourHourTime.group(1)!);
  final minute = int.parse(twentyFourHourTime.group(2)!);
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return _strictDateTime(year, month, day, hour, minute);
}

DateTime? _strictDateTime(int year, int month, int day, int hour, int minute) {
  final parsed = DateTime(year, month, day, hour, minute);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}
