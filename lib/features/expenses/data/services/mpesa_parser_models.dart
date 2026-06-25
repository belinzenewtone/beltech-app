enum MpesaParseRoute { directLedger, reviewQueue, quarantine }

enum MpesaConfidence { high, medium, low }

enum MpesaTransactionType {
  sent,
  received,
  paybill,
  buyGoods,
  withdrawal,
  deposit,
  airtime,
  reversal,
  fulizaDraw,
  fulizaRepayment,
  unknown,
}

class ParsedMpesaCandidate {
  const ParsedMpesaCandidate({
    required this.mpesaCode,
    required this.title,
    required this.category,
    required this.amountKes,
    required this.occurredAt,
    required this.rawMessage,
    required this.transactionType,
    required this.confidence,
    required this.route,
    required this.sourceHash,
    required this.semanticHash,
    this.counterparty,
    this.reason,
    this.paybillAccount,
    this.balanceAfterKes,
  });

  final String mpesaCode;
  final String title;
  final String category;
  final double amountKes;
  final DateTime occurredAt;
  final String rawMessage;
  final MpesaTransactionType transactionType;
  final MpesaConfidence confidence;
  final MpesaParseRoute route;
  final String sourceHash;
  final String semanticHash;
  final String? counterparty;
  final String? reason;
  final String? paybillAccount;
  final double? balanceAfterKes;

  double get confidenceScore => switch (confidence) {
    MpesaConfidence.high => 0.92,
    MpesaConfidence.medium => 0.68,
    MpesaConfidence.low => 0.42,
  };
}

class ParsedMpesaTransaction {
  const ParsedMpesaTransaction({
    required this.title,
    required this.category,
    required this.amountKes,
    required this.occurredAt,
    required this.rawMessage,
    this.balanceAfterKes,
  });

  final String title;
  final String category;
  final double amountKes;
  final DateTime occurredAt;
  final String rawMessage;
  final double? balanceAfterKes;
}
