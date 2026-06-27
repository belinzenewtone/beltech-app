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
      RegExp('$_wb(?:has been reversed|transaction.*reversed)'),
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
  //   "Ksh 200.00 paid from your Fuliza M-PESA ..."
  MpesaParserRule(
    type: MpesaTransactionType.fulizaRepayment,
    confidence: MpesaConfidence.high,
    reason: 'fuliza_repayment',
    requiredPatterns: [
      RegExp('from your m-?pesa has been used'),
      RegExp('${_wb}outstanding\\s+fuliza'),
    ],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.fulizaRepayment,
    confidence: MpesaConfidence.high,
    reason: 'fuliza_repayment',
    requiredPatterns: [
      RegExp('${_wb}paid\\s+from\\s+your\\s+fuliza'),
    ],
  ),

  // Fuliza draw:
  //   "Ksh 1,000.00 has been added to your M-PESA by Fuliza M-PESA."
  //   "Ksh 500.00 Fuliza M-PESA amount credited ..."
  MpesaParserRule(
    type: MpesaTransactionType.fulizaDraw,
    confidence: MpesaConfidence.high,
    reason: 'fuliza_draw',
    requiredPatterns: [
      RegExp('added to your m-?pesa'),
      RegExp('${_wb}by\\s+fuliza'),
    ],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.fulizaDraw,
    confidence: MpesaConfidence.high,
    reason: 'fuliza_draw',
    requiredPatterns: [
      RegExp('${_wb}fuliza\\s+m-?pesa'),
      RegExp('${_wb}amount\\s+credited'),
    ],
  ),

  // Received variants.
  // "You have received Ksh X from NAME on DATE"
  MpesaParserRule(
    type: MpesaTransactionType.received,
    confidence: MpesaConfidence.high,
    reason: 'receive_you_have',
    requiredPatterns: [
      RegExp('${_wb}you\\s+have\\s+received'),
      RegExp('$_wb(?:ksh|kes)\\s*\\d'),
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

  // Paybill: account keyword appears anywhere after "sent to" / "paid to".
  // Catches variants like "sent to KPLC account 998877" or "paid to DSTV acc#12345".
  MpesaParserRule(
    type: MpesaTransactionType.paybill,
    confidence: MpesaConfidence.high,
    reason: 'paybill_account_keyword',
    requiredPatterns: [
      RegExp('$_wb(?:sent|paid)\\s+to'),
      RegExp(
        '$_wb(?:for\\s+)?(?:account|acc(?:ount)?)(?:\\s*(?:no\\.?|number|#))?',
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
      RegExp('$_wb(?:repay.*fuliza|fuliza.*repay)'),
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
  String message, {
  String? sender,
}) {
  final normalized = message.toLowerCase();
  for (final rule in _primaryRules) {
    if (rule.matches(normalized)) {
      return (
        rule.type,
        _adjustConfidenceForSender(rule.confidence, sender),
        rule.reason,
      );
    }
  }
  for (final rule in _fallbackRules) {
    if (rule.matches(normalized)) {
      return (
        rule.type,
        _adjustConfidenceForSender(rule.confidence, sender),
        rule.reason,
      );
    }
  }
  return (
    MpesaTransactionType.unknown,
    _adjustConfidenceForSender(MpesaConfidence.low, sender),
    'fallback',
  );
}

MpesaConfidence _adjustConfidenceForSender(
  MpesaConfidence base,
  String? sender,
) {
  if (sender == null || sender.isEmpty) {
    return base;
  }
  final lower = sender.toLowerCase();
  // Messages from the official M-PESA sender are the most trustworthy.
  if (lower.contains('mpesa')) {
    return base;
  }
  // Bank / non-M-Pesa senders are more likely to be cross-service noise or
  // promotional messages, so downgrade one confidence level.
  if (_looksLikeBankOrShortcode(lower)) {
    return _downgradeConfidence(base);
  }
  return base;
}

bool _looksLikeBankOrShortcode(String sender) {
  if (RegExp(r'^\d+$').hasMatch(sender)) {
    return true;
  }
  const bankNames = [
    'kcb',
    'equity',
    'coop',
    'absa',
    'ncba',
    'stanbic',
    'barclays',
    'family',
    'im',
    'dtb',
    'sbm',
    'habib',
    'gulf',
    'postbank',
    'kwft',
    'unaitas',
    'm-shwari',
    'kcb m-pesa',
    'hustler fund',
  ];
  for (final name in bankNames) {
    if (sender.contains(name)) {
      return true;
    }
  }
  return false;
}

MpesaConfidence _downgradeConfidence(MpesaConfidence confidence) =>
    switch (confidence) {
      MpesaConfidence.high => MpesaConfidence.medium,
      MpesaConfidence.medium => MpesaConfidence.low,
      MpesaConfidence.low => MpesaConfidence.low,
    };
