/// Golden-corpus fixture types for the SMS parser accuracy harness (Phase P0).
///
/// Ported 1:1 from the Kotlin reference app's parser fixtures
/// (`MpesaParserFixtures.kt`, `BankParserFixtures.kt`). The string vocabularies
/// below are kept identical to the Kotlin side so the corpus stays portable and
/// diffable; the harness maps the Dart parser's enums onto these strings.
///
/// expectedKind vocabulary (M-Pesa):
///   received · sent · airtime · paybill · buy_goods · deposit · withdraw ·
///   reversal · fuliza_repayment · loan · fuliza_charge · unknown
/// expectedRoute vocabulary:
///   direct_ledger · review_queue · quarantine
/// expectedConfidence vocabulary:
///   high · medium · low
library;

class ParserFixture {
  const ParserFixture({
    required this.body,
    this.expectedKind,
    this.expectedAmount,
    this.expectedBalance,
    this.expectedConfidence,
    this.expectedRoute,
    this.expectedCounterpartyContains,
    this.shouldIgnore = false,
    this.expectedError,
  });

  final String body;
  final String? expectedKind;
  final double? expectedAmount;
  final double? expectedBalance;
  final String? expectedConfidence;
  final String? expectedRoute;
  final String? expectedCounterpartyContains;

  /// Expected to be filtered out (Fuliza service notice, etc.) — not a ledger row.
  final bool shouldIgnore;

  /// When set, the parser is expected to reject the message (return null),
  /// carrying this reason code on the Kotlin side.
  final String? expectedError;
}

class BankFixture {
  const BankFixture({
    required this.body,
    this.expectedInstitution,
    this.expectedKind, // 'debit' | 'credit'
    this.expectedAmount,
    this.expectedBalance,
    this.expectedRoute,
    this.shouldIgnore = false,
    this.expectedError,
  });

  final String body;
  final String? expectedInstitution;
  final String? expectedKind;
  final double? expectedAmount;
  final double? expectedBalance;
  final String? expectedRoute;
  final bool shouldIgnore;
  final String? expectedError;
}
