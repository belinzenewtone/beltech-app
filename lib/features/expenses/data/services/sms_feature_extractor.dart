/// Extracts a numeric feature vector from a raw SMS body for use by
/// [TransactionDecisionTree].
///
/// Features are orthogonal to the main parser's rule-matching logic so the
/// decision tree provides genuine independent signal.
///
/// All features are normalised to [0.0, 1.0] so decision-tree thresholds
/// remain stable across SMS lengths and amount scales.
class SmsFeatureVector {
  const SmsFeatureVector({
    required this.hasTransactionCode,
    required this.hasAmount,
    required this.amountTier,
    required this.hasDate,
    required this.hasMpesaKeyword,
    required this.numericDensity,
    required this.hasBalance,
    required this.hasFee,
    required this.hasReversalSignal,
    required this.hasFulizaSignal,
    required this.normBodyLength,
    required this.hasBothParties,
  });

  /// 1.0 if body contains a 9–10 char alphanumeric M-Pesa code.
  final double hasTransactionCode;

  /// 1.0 if at least one Ksh/KES amount was found.
  final double hasAmount;

  /// Amount magnitude tier: 0.0 (<100), 0.25 (<1k), 0.5 (<10k), 0.75 (<100k), 1.0 (≥100k).
  final double amountTier;

  /// 1.0 if body contains a date-like string.
  final double hasDate;

  /// 1.0 if body contains M-Pesa/MPESA keyword.
  final double hasMpesaKeyword;

  /// Ratio of numeric characters to total body length (0.0–1.0).
  final double numericDensity;

  /// 1.0 if body contains a balance-after marker.
  final double hasBalance;

  /// 1.0 if body contains a transaction fee/charge marker.
  final double hasFee;

  /// 1.0 if body contains a reversal keyword.
  final double hasReversalSignal;

  /// 1.0 if body contains a Fuliza keyword.
  final double hasFulizaSignal;

  /// Normalised body length (0.0 = 0 chars, 1.0 = 500+ chars).
  final double normBodyLength;

  /// 1.0 if body contains both a sender and recipient name pattern.
  final double hasBothParties;
}

class SmsFeatureExtractor {
  const SmsFeatureExtractor();

  // Safaricom 2026+ codes may be all-letter (e.g. UCNDLAHMKE) — only require
  // at least one letter so we don't miss them in the decision-tree feature.
  static final _codeRe = RegExp(
    r'\b(?=[A-Za-z0-9]*[A-Za-z])([A-Za-z0-9]{9,10})\b',
  );
  static final _amountRe = RegExp(
    r'(?:ksh|kes|ksh)\s?[\d,]+(?:\.\d{1,2})?',
    caseSensitive: false,
  );
  static final _dateRe = RegExp(
    r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}|\d{4}-\d{2}-\d{2}',
  );
  static final _balanceRe = RegExp(
    r'(?:new|available)?\s*balance\s*(?:is|:)',
    caseSensitive: false,
  );
  static final _feeRe = RegExp(
    r'(?:transaction\s+cost|charges?|fees?)[\s:]+',
    caseSensitive: false,
  );
  static final _reversalRe = RegExp(
    r'\breversed?\b|\breversal\b',
    caseSensitive: false,
  );
  static final _fulizaRe = RegExp(r'fuliza', caseSensitive: false);
  static final _sentToRe = RegExp(
    r'sent\s+to\s+[A-Z][A-Za-z]',
    caseSensitive: false,
  );
  static final _fromRe = RegExp(
    r'(?:from|received\s+from)\s+[A-Z][A-Za-z]',
    caseSensitive: false,
  );

  SmsFeatureVector extract(String sms) {
    final body = sms.length > 500 ? sms.substring(0, 500) : sms;
    final lower = sms.toLowerCase();

    final hasCode = _codeRe.hasMatch(sms) ? 1.0 : 0.0;
    final amountMatch = _amountRe.firstMatch(sms);
    final hasAmt = amountMatch != null ? 1.0 : 0.0;

    double amtTier = 0.0;
    if (amountMatch != null) {
      final raw = amountMatch
          .group(0)!
          .replaceAll(RegExp(r'ksh|kes', caseSensitive: false), '')
          .replaceAll(',', '')
          .trim();
      final rawAmt = double.tryParse(raw) ?? 0.0;
      amtTier = rawAmt < 100
          ? 0.0
          : rawAmt < 1000
          ? 0.25
          : rawAmt < 10000
          ? 0.5
          : rawAmt < 100000
          ? 0.75
          : 1.0;
    }

    final numericCount = body.codeUnits.where((c) => c >= 48 && c <= 57).length;
    final numericDens = body.isEmpty
        ? 0.0
        : (numericCount / body.length).clamp(0.0, 1.0);

    final hasBoth =
        (_sentToRe.hasMatch(sms) || _fromRe.hasMatch(sms)) ? 1.0 : 0.0;

    return SmsFeatureVector(
      hasTransactionCode: hasCode,
      hasAmount: hasAmt,
      amountTier: amtTier,
      hasDate: _dateRe.hasMatch(sms) ? 1.0 : 0.0,
      hasMpesaKeyword:
          (lower.contains('mpesa') || lower.contains('m-pesa')) ? 1.0 : 0.0,
      numericDensity: numericDens,
      hasBalance: _balanceRe.hasMatch(sms) ? 1.0 : 0.0,
      hasFee: _feeRe.hasMatch(sms) ? 1.0 : 0.0,
      hasReversalSignal: _reversalRe.hasMatch(sms) ? 1.0 : 0.0,
      hasFulizaSignal: _fulizaRe.hasMatch(sms) ? 1.0 : 0.0,
      normBodyLength: (sms.length / 500.0).clamp(0.0, 1.0),
      hasBothParties: hasBoth,
    );
  }
}
