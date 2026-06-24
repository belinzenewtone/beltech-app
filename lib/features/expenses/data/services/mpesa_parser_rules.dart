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
  final List<RegExp> requiredPatterns;

  bool matches(String normalizedMessage) {
    return requiredPatterns.every(
      (pattern) => pattern.hasMatch(normalizedMessage),
    );
  }
}

const _wordBoundary = r'(?<![a-z0-9])';

final List<MpesaParserRule> mpesaParserRules = [
  MpesaParserRule(
    type: MpesaTransactionType.reversal,
    confidence: MpesaConfidence.high,
    reason: 'reversal',
    requiredPatterns: [RegExp('${_wordBoundary}has\\s+been\\s+reversed')],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.fulizaRepayment,
    confidence: MpesaConfidence.high,
    reason: 'fuliza_repayment',
    requiredPatterns: [RegExp('${_wordBoundary}from\\s+your\\s+fuliza')],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.fulizaDraw,
    confidence: MpesaConfidence.high,
    reason: 'fuliza',
    requiredPatterns: [
      RegExp('${_wordBoundary}fuliza\\s+m-?pesa'),
      RegExp('${_wordBoundary}credited'),
    ],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.received,
    confidence: MpesaConfidence.high,
    reason: 'receive',
    requiredPatterns: [RegExp('${_wordBoundary}received\\s+from')],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.paybill,
    confidence: MpesaConfidence.high,
    reason: 'paybill',
    requiredPatterns: [
      RegExp('${_wordBoundary}sent\\s+to'),
      RegExp(
        '${_wordBoundary}for\\s+(?:account|acc(?:ount)?)(?:\\s*(?:no\\.?|number|#))?',
      ),
    ],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.buyGoods,
    confidence: MpesaConfidence.high,
    reason: 'buy_goods',
    requiredPatterns: [RegExp('${_wordBoundary}paid\\s+to')],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.sent,
    confidence: MpesaConfidence.high,
    reason: 'sent',
    requiredPatterns: [RegExp('${_wordBoundary}sent\\s+to')],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.withdrawal,
    confidence: MpesaConfidence.medium,
    reason: 'withdrawal',
    requiredPatterns: [RegExp('${_wordBoundary}withdraw')],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.airtime,
    confidence: MpesaConfidence.medium,
    reason: 'airtime',
    requiredPatterns: [RegExp('${_wordBoundary}airtime')],
  ),
  MpesaParserRule(
    type: MpesaTransactionType.deposit,
    confidence: MpesaConfidence.medium,
    reason: 'deposit',
    requiredPatterns: [RegExp('${_wordBoundary}deposit')],
  ),
];

(MpesaTransactionType, MpesaConfidence, String) detectMpesaTransaction(
  String message,
) {
  final normalized = message.toLowerCase();
  for (final rule in mpesaParserRules) {
    if (rule.matches(normalized)) {
      return (rule.type, rule.confidence, rule.reason);
    }
  }
  return (MpesaTransactionType.unknown, MpesaConfidence.low, 'fallback');
}
