final List<RegExp> _fulizaNoticePatterns = [
  RegExp(r'fuliza.*(?:limit|available)', caseSensitive: false),
  RegExp(r'dial\s*\*\d{2,4}#', caseSensitive: false),
  RegExp(r'fuliza service', caseSensitive: false),
];

final List<RegExp> _ambiguousSuccessPatterns = [
  RegExp(r'transaction completed successfully', caseSensitive: false),
  RegExp(r'your transaction was successful', caseSensitive: false),
];

bool shouldIgnoreMpesaSms(String message) =>
    _fulizaNoticePatterns.any((pattern) => pattern.hasMatch(message));

bool isAmbiguousSuccessReceipt(String message) =>
    _ambiguousSuccessPatterns.any((pattern) => pattern.hasMatch(message));

String cleanCounterparty(String value) => value
    .replaceAll(RegExp(r'\s+\d{9,12}$'), '')
    .replaceAll(RegExp(r'\s+via\s+kopo\s+kopo.*$', caseSensitive: false), '')
    .replaceAll(RegExp(r'\s+new\s+m-pesa.*$', caseSensitive: false), '')
    .trim();
