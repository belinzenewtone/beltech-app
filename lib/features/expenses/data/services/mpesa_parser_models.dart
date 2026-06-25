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
  /// Balance-update notice from Safaricom ("Access Fee charged …").
  /// Not imported as a ledger transaction — pipeline records it in
  /// fuliza_lifecycle_events and updates the outstanding balance only.
  fulizaCharge,
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
    this.isReceivedReversal = false,
    this.fulizaOutstandingKes,
    this.fulizaAvailableLimitKes,
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

  /// True when a *received* payment was reversed (net effect: outgoing debit).
  final bool isReceivedReversal;

  /// Total Fuliza outstanding balance extracted from the SMS (charge notices).
  final double? fulizaOutstandingKes;

  /// Available Fuliza limit extracted from the SMS (charge notices / repayments).
  final double? fulizaAvailableLimitKes;

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
