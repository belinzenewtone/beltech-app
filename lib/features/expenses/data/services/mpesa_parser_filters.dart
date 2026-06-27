// Non-transactional Safaricom messages that should never be parsed as
// transactions. Keep this list tight: only genuine marketing / USSD-prompt
// messages with no financial value belong here.
//
// IMPORTANT: do NOT add patterns that could match real transactional SMS:
//  • Fuliza repayments contain "available Fuliza … limit" → was incorrectly
//    filtered before; that broad pattern has been removed.
//  • Fuliza charge notices contain "Access Fee charged" → parsed as
//    fulizaCharge (balance-update-only), not filtered out.
final List<RegExp> _ignoreSmsPatterns = [
  // Fuliza activation / approval / limit-change marketing messages
  RegExp(
    r'fuliza.*(?:activated|approved|eligible|limit.*(?:increased|updated|changed))',
    caseSensitive: false,
  ),
  RegExp(
    r'(?:activated|approved|eligible)\s+for\s+fuliza',
    caseSensitive: false,
  ),
  // USSD-prompt / "dial *XXX#" service messages (no money moved)
  RegExp(r'dial\s*\*\d{2,4}#', caseSensitive: false),
  // Pure balance-notification messages (no transaction keywords).
  RegExp(
    r'^(?!.*\b(?:confirmed|sent|received|paid)\b).*your m-?pesa balance (?:is|was)',
    caseSensitive: false,
  ),
];

final List<RegExp> _ambiguousSuccessPatterns = [
  RegExp(r'transaction completed successfully', caseSensitive: false),
  RegExp(r'your transaction was successful', caseSensitive: false),
];

bool shouldIgnoreMpesaSms(String message) =>
    _ignoreSmsPatterns.any((pattern) => pattern.hasMatch(message));

bool isAmbiguousSuccessReceipt(String message) =>
    _ambiguousSuccessPatterns.any((pattern) => pattern.hasMatch(message));

String cleanCounterparty(String value) => value
    .replaceAll(RegExp(r'\s+\d{9,12}$'), '')
    .replaceAll(RegExp(r'\s+via\s+kopo\s+kopo.*$', caseSensitive: false), '')
    .replaceAll(RegExp(r'\s+new\s+m-pesa.*$', caseSensitive: false), '')
    .trim();
