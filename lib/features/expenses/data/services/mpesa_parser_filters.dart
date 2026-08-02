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
  // USSD-prompt / "dial *XXX#" service messages (no money moved).
  // Guarded: modern Safaricom transaction SMS append a "Dial *334#" promo tail,
  // so only ignore dial prompts that carry NO transaction keyword — otherwise a
  // real "sent to …/Confirmed …" with a promo tail was silently dropped.
  RegExp(
    r'^(?!.*\b(?:confirmed|sent|received|paid)\b).*dial\s*\*\d{2,4}#',
    caseSensitive: false,
  ),
  // Pure balance-notification messages (no transaction keywords).
  RegExp(
    r'^(?!.*\b(?:confirmed|sent|received|paid)\b).*your m-?pesa balance (?:is|was)',
    caseSensitive: false,
  ),
  // Failed / rejected transactions — no money moved, nothing to import.
  // "Failed. Insufficient funds ...", "Failed, you have entered the wrong PIN",
  // "Transaction failed, M-PESA cannot complete payment ...", "The number you
  // are trying to pay has not joined the service", "You have cancelled the
  // transaction", "M-PESA is unable to process your request".
  //
  // Guarded: a "Confirmed ... has been used to pay" Fuliza-repayment phrase may
  // follow a failure notice ("Failed. Insufficient funds ... Confirmed. Ksh
  // 632.59 from your M-PESA has been used to fully pay your outstanding
  // Fuliza...") — those MUST still parse, so only ignore when no Confirmed
  // transaction phrase is present.
  RegExp(
    r'^(?!.*\bconfirmed\b)(?:failed|transaction\s+failed)[,.]?.*',
    caseSensitive: false,
  ),
  RegExp(
    r'^(?!.*\b(?:confirmed|sent|received|paid|credited)\b).*(?:insufficient\s+funds|wrong\s+pin|has\s+not\s+joined\s+the\s+service|cannot\s+(?:complete|send|pay)|unable\s+to\s+process|unsuccessful|cancelled\s+the\s+transaction|format\s+of\s+your\s+account\s+number\s+is\s+incorrect|till\s+number\s+entered\s+is\s+incorrect).*',
    caseSensitive: false,
  ),
  // Balance-only / account-status notices with no money moved:
  // "Confirmed. Your account balance was: ..."
  RegExp(
    r'confirmed\.?\s+your\s+(?:m-?pesa\s+)?account\s+balance\s+was',
    caseSensitive: false,
  ),
  // Loan-limit / T&C notices ("Confirmed. Your loan limit is 0.00. A fee of
  // 8.85% ...") — no transaction.
  RegExp(
    r'confirmed\.?\s+your\s+loan\s+limit\s+is',
    caseSensitive: false,
  ),
  // Business↔M-PESA account transfers ("moved from your business account to
  // your M-PESA account" / "moved from your M-PESA account to your business
  // account") — internal transfers, not expenses/income.
  RegExp(
    r'moved\s+from\s+your\s+(?:business\s+account\s+to\s+your\s+m-?pesa\s+account|m-?pesa\s+account\s+to\s+your\s+business\s+account)',
    caseSensitive: false,
  ),
  // Fuliza opt-in / zero-limit notices ("successfully opted into Fuliza
  // M-PESA", "your Fuliza M-PESA limit is Ksh 0.00") — no transaction.
  RegExp(
    r'(?:successfully\s+opted\s+into\s+fuliza|your\s+fuliza\s+m-?pesa\s+limit\s+is\s+(?:ksh|kes)\s*0\.?0*)',
    caseSensitive: false,
  ),
  // SIM / line activation notices — non-financial.
  RegExp(
    r'your\s+sim\s+card\s+has\s+been\s+activated',
    caseSensitive: false,
  ),
  // M-PESA account activation / PIN setup notices — non-transactions.
  RegExp(
    r'(?:your\s+identity\s+in\s+m-?pesa\s+is\s+activated|to\s+activate\s+your\s+m-?pesa\s+account|create\s+your\s+new\s+secret\s+pin)',
    caseSensitive: false,
  ),
  // In-progress transaction status notices — not a completed transaction.
  RegExp(
    r'an\s+m-?pesa\s+transaction\s+is\s+currently\s+underway',
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
