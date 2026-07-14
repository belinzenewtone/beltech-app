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
    this.matchedRulePhase,
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

  /// Which rule phase produced the classification: 1 = primary structural rules,
  /// 2 = keyword fallback rules, 3 = last-resort keyword scan, 0 = no match.
  final int? matchedRulePhase;

  double get confidenceScore => switch (confidence) {
    MpesaConfidence.high => 0.92,
    MpesaConfidence.medium => 0.68,
    MpesaConfidence.low => 0.42,
  };
}

// ── Sealed parse outcome ─────────────────────────────────────────────────────
// Every code path that processes an SMS returns exactly one of these variants.
// The import pipeline pattern-matches on the type to decide what to persist.

sealed class ParseOutcome {
  const ParseOutcome();
}

/// SMS parsed successfully and routed to the ledger or review queue.
final class ParseSuccess extends ParseOutcome {
  const ParseSuccess({required this.candidate});
  final ParsedMpesaCandidate candidate;
}

/// SMS is a known duplicate of an already-accepted transaction.
final class ParseDuplicate extends ParseOutcome {
  const ParseDuplicate({required this.dupeKey});
  /// Either a source hash or semantic hash that matched an existing row.
  final String dupeKey;
}

/// SMS could not be classified above the quarantine threshold.
final class ParseFailure extends ParseOutcome {
  const ParseFailure({
    required this.reason,
    required this.rawMessage,
    this.matchedRulePhase,
  });
  final String reason;
  final String rawMessage;
  final int? matchedRulePhase;
}

/// Fuliza charge notice — updates the outstanding balance, not the ledger.
final class ParseFulizaUpdate extends ParseOutcome {
  const ParseFulizaUpdate({required this.candidate});
  final ParsedMpesaCandidate candidate;
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
