import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';

class MpesaParserRule {
  const MpesaParserRule({
    required this.type,
    required this.confidence,
    required this.reason,
    required this.requiredPatterns,
  });

  final MpesaTransactionType type;
  final MpesaConfidence confidence;
  final String reason;

  /// All patterns must match (AND-logic). Message is already lowercased.
  final List<RegExp> requiredPatterns;

  bool matches(String normalizedMessage) =>
      requiredPatterns.every((p) => p.hasMatch(normalizedMessage));
}

// Negative lookbehind: pattern must not be preceded by a letter or digit.
const _wb = r'(?<![a-z0-9])';

// ── Phase 1 — Structural primary rules ────────────────────────────────────────
// High-precision multi-word patterns. Order matters: more specific first.

final List<MpesaParserRule> _primaryRules = [
  // Reversal: canonical Safaricom phrase
  MpesaParserRule(
    type: MpesaTransactionType.reversal,
    confidence: MpesaConfidence.high,
    reason: 'reversal',
    requiredPatterns: [
      RegExp('${_wb}(?:has been reversed|transaction.*reversed)'),
    ],
  ),

  // Fuliza charge notice: "Access Fee charged … Total Fuliza … outstanding"
  // These carry no transaction code and are balance-update-only events.
  MpesaParserRule(
    type: MpesaTransactionType.fulizaCharge,
    confidence: MpesaConfidence.high,
    reason: 'fuliza_charge',
    requiredPatterns: [
      RegExp('${_wb}access\\s+fee\\s+charged'),
      RegExp('${_wb}fuliza'),
    ],
  ),

  // Fuliza repayment:
  //   "Ksh 730.00 from your M-PESA has been used to partially pay your
  //    outstanding Fuliza M-PESA."
  MpesaParserRule(
    type: MpesaTransactionType.fulizaRepayment,
    confidence: MpesaConfidence.high,
    reason: 'fuliza_repayment',
    requiredPatterns: [
      RegExp('from your m-?pesa has been used'),
      RegExp('${_wb}outstanding\\s+fuliza'),
    ],
  ),

  // Fuliza draw:
  //   "Ksh 1,000.00 has been added to your M-PESA by Fuliza M-PESA."
  MpesaParserRule(
    type: MpesaTransactionType.fulizaDraw,
    confidence: MpesaConfidence.high,
    reason: 'fuliza_draw',
    requiredPatterns: [
      RegExp('added to your m-?pesa'),
      RegExp('${_wb}by\\s+fuliza'),
    ],
  ),

  // Received: "Ksh X received from NAME on DATE"
  MpesaParserRule(
    type: MpesaTransactionType.received,
    confidence: MpesaConfidence.high,
    reason: 'receive',
    requiredPatterns: [RegExp('${_wb}received\\s+from')],
  ),

  // Paybill: "sent to BILLER for account ACCT"
  MpesaParserRule(
    type: MpesaTransactionType.paybill,
    confidence: MpesaConfidence.high,
    reason: 'paybill',
    requiredPatterns: [
      RegExp('${_wb}sent\\s+to'),
      RegExp(
        '${_wb}for\\s+(?:account|acc(?:ount)?)(?:\\s*(?:no\\.?|number|#))?',
      ),
    ],
  ),

  // Buy Goods: "paid to MERCHANT on"
  MpesaParserRule(
    type: MpesaTransactionType.buyGoods,
    confidence: MpesaConfidence.high,
    reason: 'buy_goods',
    requiredPatterns: [RegExp('${_wb}paid\\s+to')],
  ),

  // Sent: "sent to NAME on" (after paybill guard above)
  MpesaParserRule(
    type: MpesaTransactionType.sent,
    confidence: MpesaConfidence.high,
    reason: 'sent',
    requiredPatterns: [RegExp('${_wb}sent\\s+to')],
  ),
];

// ── Phase 2 — Keyword fallback rules ──────────────────────────────────────────
// Single-keyword patterns at medium confidence.  Used only when no primary
// rule fires.  Order matters: most specific / least ambiguous first.

final List<MpesaParserRule> _fallbackRules = [
  // Fuliza repayment alt phrasing (no "from your m-pesa has been used")
  MpesaParserRule(
    type: MpesaTransactionType.fulizaRepayment,
    confidence: MpesaConfidence.medium,
    reason: 'fuliza_repayment_kw',
    requiredPatterns: [
      RegExp('${_wb}(?:repay.*fuliza|fuliza.*repay)'),
    ],
  ),

  // Fuliza draw alt phrasing (no "by fuliza", but has "fuliza m-pesa" + "added")
  MpesaParserRule(
    type: MpesaTransactionType.fulizaDraw,
    confidence: MpesaConfidence.medium,
    reason: 'fuliza_draw_kw',
    requiredPatterns: [
      RegExp('${_wb}fuliza\\s+m-?pesa'),
      RegExp('${_wb}added'),
    ],
  ),

  // Withdrawal
  MpesaParserRule(
    type: MpesaTransactionType.withdrawal,
    confidence: MpesaConfidence.medium,
    reason: 'withdrawal',
    requiredPatterns: [RegExp('${_wb}withdraw')],
  ),

  // Airtime
  MpesaParserRule(
    type: MpesaTransactionType.airtime,
    confidence: MpesaConfidence.medium,
    reason: 'airtime',
    requiredPatterns: [RegExp('${_wb}airtime')],
  ),

  // Deposit
  MpesaParserRule(
    type: MpesaTransactionType.deposit,
    confidence: MpesaConfidence.medium,
    reason: 'deposit',
    requiredPatterns: [RegExp('${_wb}deposit')],
  ),
];

/// Combined list (primary + fallback) — exposed for diagnostics / tests.
final List<MpesaParserRule> mpesaParserRules = [
  ..._primaryRules,
  ..._fallbackRules,
];

/// Three-phase detection:
///   Phase 1 — structural primary rules (high confidence)
///   Phase 2 — keyword fallback rules   (medium confidence)
///   Phase 3 — unknown / low confidence (no rule matched)
(MpesaTransactionType, MpesaConfidence, String) detectMpesaTransaction(
  String message,
) {
  final normalized = message.toLowerCase();
  for (final rule in _primaryRules) {
    if (rule.matches(normalized)) {
      return (rule.type, rule.confidence, rule.reason);
    }
  }
  for (final rule in _fallbackRules) {
    if (rule.matches(normalized)) {
      return (rule.type, rule.confidence, rule.reason);
    }
  }
  return (MpesaTransactionType.unknown, MpesaConfidence.low, 'fallback');
}
