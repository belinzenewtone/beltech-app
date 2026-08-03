import 'dart:convert';
import 'dart:isolate';

import 'package:beltech/features/expenses/data/services/airtel_money_parser.dart';
import 'package:beltech/features/expenses/data/services/generic_bank_parser.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_filters.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_rules.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';
import 'package:beltech/features/expenses/data/services/sms_confidence_scorer.dart';
import 'package:beltech/features/expenses/data/services/transaction_decision_tree.dart';
import 'package:crypto/crypto.dart';

/// A single unit of work that can be sent to a parser isolate.
class SmsParseJob {
  const SmsParseJob(
    this.rawMessage, {
    this.fallbackOccurredAt,
    this.sender,
  });

  final String rawMessage;
  final DateTime? fallbackOccurredAt;

  /// The SMS sender address, if available.
  final String? sender;
}

class MpesaParserService {
  const MpesaParserService();

  static const _bankParser = GenericBankParser();
  static const _airtelParser = AirtelMoneyParser();
  static const _decisionTree = TransactionDecisionTree();

  // Matches any 10-char alphanumeric token not surrounded by alphanumerics.
  // Requires at least one letter AND one digit (via post-extraction check).
  static final RegExp _codePattern = RegExp(
    r'(?<![A-Z0-9])([A-Z0-9]{10})(?![A-Z0-9])',
    caseSensitive: false,
  );
  static final RegExp _amountPattern = RegExp(
    r'(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  // Verb tokens whose position we use to pick the closest amount.
  static final RegExp _verbPattern = RegExp(
    r'\b(?:sent|paid|received|withdrawn|credited|charged|deposited)\b',
    caseSensitive: false,
  );
  // Captures transaction fee from "Transaction cost[,/:] Ksh X" or "Service charge".
  static final RegExp _feePattern = RegExp(
    r'(?:transaction\s+cost|service\s+charge)[\s,:.]*(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _dateTimePattern = RegExp(
    r'on\s+(\d{1,2}/\d{1,2}/\d{2,4})\s+at\s+(\d{1,2}:\d{2}\s?(?:am|pm)?)',
    caseSensitive: false,
  );
  static final RegExp _balancePattern = RegExp(
    r'(?:new\s+m-pesa\s+balance(?:\s+is)?|balance(?:\s+is)?)\s*(?:ksh|kes)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _paybillPattern = RegExp(
    r'(?:for\s+)?(?:account|acc(?:ount)?)\s*(?:no\.?|number|#)?\s*([a-z0-9-]{3,})',
    caseSensitive: false,
  );
  static final RegExp _sentToPattern = RegExp(
    r'sent to\s+([a-z0-9 .,&-]{3,}?)(?=\s+(?:for\s+(?:account|acc(?:ount)?)(?:\s*(?:no\.?|number|#))?|on)\b|[.]|$)',
    caseSensitive: false,
  );
  // Fallback for the newer "Customer transfer of Ksh X to NAME" and
  // "paybill payment to BILLER" phrasings that lack the literal "sent to".
  // The name class excludes digits so it stops before a trailing phone number.
  static final RegExp _transferToPattern = RegExp(
    r"\bto\s+([a-z .,&'-]{3,}?)(?=\s+\d|\s+for\b|\s+on\b|[.]|$)",
    caseSensitive: false,
  );
  static final RegExp _receivedFromPattern = RegExp(
    r'received\b.*?\s+from\s+([a-z0-9 .,&-]{3,}?)(?=\s+on\b|[.]|$)',
    caseSensitive: false,
  );
  static final RegExp _paidToPattern = RegExp(
    r'paid to\s+([a-z0-9 .,&-]{3,}?)(?=\s+on\b|[.]|$)',
    caseSensitive: false,
  );

  // Fuliza-specific extraction patterns
  static final RegExp _fulizaOutstandingPattern = RegExp(
    r'(?:total\s+fuliza[^.]*outstanding\s+amount\s+is|outstanding\s+amount\s+of)\s+(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _fulizaAvailableLimitPattern = RegExp(
    r'(?:(?:your\s+)?available\s+)?fuliza\s+m-?pesa\s+limit\s+is\s+(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  List<ParsedMpesaTransaction> parseBulkText(String payload) {
    final chunks = payload
        .split(RegExp(r'(?:\r?\n){2,}'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return parseMany(chunks);
  }

  List<ParsedMpesaTransaction> parseMany(List<String> messages) {
    return parseManyDetailed(messages)
        .where((item) => item.route != MpesaParseRoute.quarantine)
        .map(
          (item) => ParsedMpesaTransaction(
            title: item.title,
            category: item.category,
            amountKes: item.amountKes,
            occurredAt: item.occurredAt,
            rawMessage: item.rawMessage,
            balanceAfterKes: item.balanceAfterKes,
          ),
        )
        .toList();
  }

  List<ParsedMpesaCandidate> parseManyDetailed(List<String> messages) {
    final results = <ParsedMpesaCandidate>[];
    for (final message in messages) {
      final parsed = parseSingleDetailed(message);
      if (parsed != null) {
        results.add(parsed);
      }
    }
    return results;
  }

  /// Parses a list of [SmsParseJob]s off the main thread when the batch is
  /// large enough to justify isolate serialization overhead.
  ///
  /// NOTE: this drops unparseable jobs, so the result is NOT positionally
  /// aligned with the input. Callers that need to map results back to their
  /// source rows must key by [ParsedMpesaCandidate.sourceHash], or use
  /// [parseJobsInIsolateAligned] instead.
  static Future<List<ParsedMpesaCandidate>> parseJobsInIsolate(
    List<SmsParseJob> jobs,
  ) async {
    if (jobs.isEmpty) return const [];
    // Small batches are faster synchronously; avoid isolate setup cost.
    if (jobs.length < 50) {
      return _parseJobsImpl(jobs);
    }
    return Isolate.run(() => _parseJobsImpl(jobs));
  }

  /// Synchronous, position-preserving batch parse. `result[i]` is the parse of
  /// `jobs[i]` (or `null`). Runs on the calling thread — this is the entry the
  /// [ParseIsolatePool] workers invoke inside their own isolate, so it must NOT
  /// spawn further isolates.
  static List<ParsedMpesaCandidate?> parseJobsAlignedSync(
    List<SmsParseJob> jobs,
  ) => _parseJobsAlignedImpl(jobs);

  /// Like [parseJobsInIsolate] but returns a list **1:1 aligned** with [jobs]:
  /// `result[i]` is the candidate for `jobs[i]`, or `null` when that job did
  /// not parse. This is the index-safe API for the import pipeline, which maps
  /// results back to queue rows positionally — dropping nulls (as the
  /// non-aligned variant does) silently misaligns every row after the first
  /// unparseable message.
  static Future<List<ParsedMpesaCandidate?>> parseJobsInIsolateAligned(
    List<SmsParseJob> jobs,
  ) async {
    if (jobs.isEmpty) return const [];
    if (jobs.length < 50) {
      return _parseJobsAlignedImpl(jobs);
    }
    return Isolate.run(() => _parseJobsAlignedImpl(jobs));
  }

  ParsedMpesaTransaction? parseSingle(String message) {
    final detailed = parseSingleDetailed(message);
    if (detailed == null || detailed.route == MpesaParseRoute.quarantine) {
      return null;
    }
    return ParsedMpesaTransaction(
      title: detailed.title,
      category: detailed.category,
      amountKes: detailed.amountKes,
      occurredAt: detailed.occurredAt,
      rawMessage: detailed.rawMessage,
      balanceAfterKes: detailed.balanceAfterKes,
    );
  }

  ParsedMpesaCandidate? parseSingleDetailed(
    String message, {
    DateTime? fallbackOccurredAt,
    String? sender,
  }) {
    // Keyword-hints fast path: discard messages with no financial content
    // before the more expensive normalizeParserText + looksLikeMpesaMessage
    // call chain. This handles the majority of non-financial SMS in O(n) with
    // a small constant via short-circuiting String.contains.
    final bodyLower = message.toLowerCase();
    final hasFinancialHint =
        bodyLower.contains('ksh') ||
        bodyLower.contains('kes') ||
        bodyLower.contains('mpesa') ||
        bodyLower.contains('m-pesa') ||
        bodyLower.contains('fuliza') ||
        bodyLower.contains('umetumwa') ||
        bodyLower.contains('umepokelewa') ||
        bodyLower.contains('salio lako') ||
        bodyLower.contains('confirmed');
    if (!hasFinancialHint) return null;

    // Airtel Money is dispatched first: its SMS use KES + AIR-prefixed IDs and
    // would otherwise be misread by the M-Pesa path (a 10-char AIR code trips
    // the M-Pesa "looks like" heuristic).
    if (_airtelParser.canParse(message, sender: sender)) {
      final airtel = _airtelParser.tryParse(
        message,
        sender: sender,
        fallbackOccurredAt: fallbackOccurredAt,
      );
      if (airtel != null) return airtel;
    }

    // Bank senders (LOOP / I&M / PesaLink / NCBA / KCB / Equity …) are
    // dispatched to the bank parser before the M-Pesa path. Their messages
    // contain "KES"/"Ksh" so they'd otherwise pass `looksLikeMpesaMessage` and
    // get mis-parsed or quarantined as M-Pesa.
    //
    // Guard: a *canonical* M-Pesa transaction (true alphanumeric 10-char code
    // + "Confirmed" + M-Pesa keyword) is never hijacked — e.g. an M-Pesa SMS
    // forwarded from a bank sender like "KCB: QQ12345678 Confirmed.
    // Ksh1,250.00 sent to ..." must stay on the M-Pesa path (with the
    // sender-aware downgrade). A bare 10-digit phone number does NOT count as
    // an M-Pesa code, so Equity "Payment of KES to ... Till No. 0723853033"
    // still goes to the bank parser.
    // Safaricom codes are 10-char alphanumeric tokens — older format included
    // digits (e.g. QW12AB34CD) but 2026+ templates use all-letter codes like
    // UCNDLAHMKE. Only require at least one letter to exclude bare phone numbers.
    final hasMpesaCode = RegExp(
      r'(?<![a-z0-9])(?=[a-z0-9]*[A-Za-z])[a-z0-9]{10}(?![a-z0-9])',
      caseSensitive: false,
    ).hasMatch(message);
    final lowerBody = message.toLowerCase();
    // A canonical M-Pesa transaction (true alphanumeric 10-char code +
    // "Confirmed") stays on the M-Pesa path even from a bank sender — e.g.
    // "KCB: QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE..." is an
    // M-Pesa message forwarded from a bank (sender-aware downgrade applies).
    // Bank messages like Equity "Your transaction of Kshs. X has been
    // credited ... MPESA Ref SL62FVV2H6" do NOT say "Confirmed" and their
    // refs are longer codes, so they dispatch to the bank parser.
    final canonicalMpesa = hasMpesaCode &&
        lowerBody.contains('confirmed') &&
        (lowerBody.contains('mpesa') || lowerBody.contains('m-pesa'));
    if (!canonicalMpesa &&
        GenericBankParser.looksLikeBankSms(message, sender: sender)) {
      // OTP / verification codes and zero-amount card holds from bank senders
      // are non-transactions — reject hard so the M-Pesa path doesn't
      // resurrect them as quarantined rows.
      if (GenericBankParser.isIgnorableBankSms(message)) {
        return null;
      }
      // Failed / cancelled MPESA messages that mention bank names (e.g.
      // "Failed. Insufficient funds... to pay Ksh199 to Equity Paybill")
      // would otherwise skip shouldIgnoreMpesaSms and land in review queue.
      if (shouldIgnoreMpesaSms(normalizeParserText(message))) {
        return null;
      }
      final bankResult = _bankParser.tryParse(
        message,
        sender: sender,
        fallbackOccurredAt: fallbackOccurredAt,
      );
      if (bankResult != null) return bankResult;
    }

    final cleaned = normalizeParserText(message);
    if (cleaned.isEmpty ||
        !looksLikeMpesaMessage(cleaned) ||
        shouldIgnoreMpesaSms(cleaned) ||
        isAmbiguousSuccessReceipt(cleaned)) {
      // Offer the message to the bank parser before giving up.
      if (cleaned.isNotEmpty && !shouldIgnoreMpesaSms(cleaned)) {
        final bankResult = _bankParser.tryParse(
          message,
          sender: sender,
          fallbackOccurredAt: fallbackOccurredAt,
        );
        if (bankResult != null) return bankResult;
      }
      return null;
    }

    // Detect type early so fulizaCharge can skip the transaction-code
    // requirement (charge notices carry no M-Pesa code).
    final (type, confidence, reason) = _detect(cleaned, sender: sender);

    String? code = _extractMpesaCode(cleaned);
    if (code == null) {
      if (type == MpesaTransactionType.fulizaCharge ||
          type == MpesaTransactionType.fulizaRepayment ||
          _isTrustedCodelessTransaction(
            cleaned,
            type: type,
            sender: sender,
          )) {
        // Derive a synthetic identifier from the message hash.
        final hash = sourceHash(cleaned);
        final prefix = switch (type) {
          MpesaTransactionType.fulizaCharge => 'FCHG',
          MpesaTransactionType.fulizaRepayment => 'FREP',
          _ => 'SYN${type.name.substring(0, 3).toUpperCase()}',
        };
        code = '$prefix${hash.substring(0, 10 - prefix.length).toUpperCase()}';
      } else {
        return _buildQuarantine(
          cleaned,
          reason: 'Missing MPESA code',
          fallbackOccurredAt: fallbackOccurredAt,
        );
      }
    }

    final amount = _extractAmount(cleaned);
    if (type != MpesaTransactionType.fulizaCharge &&
        type != MpesaTransactionType.fulizaRepayment &&
        (amount == null || amount <= 0)) {
      return _buildQuarantine(
        cleaned,
        reason: 'Missing amount',
        fallbackOccurredAt: fallbackOccurredAt,
      );
    }
    final effectiveAmount = amount ?? 0.0;

    final occurredAt =
        parseMpesaDateTime(cleaned, _dateTimePattern) ??
        fallbackOccurredAt ??
        DateTime.now();
    final balanceAfterKes = _extractBalanceAfter(cleaned);

    final isReceivedReversal =
        type == MpesaTransactionType.reversal &&
        cleaned.toLowerCase().contains('received from');

    final counterparty = _extractCounterparty(cleaned, type);
    final title = _buildTitle(type, counterparty);
    final source = sourceHash(cleaned);

    final candidate = ParsedMpesaCandidate(
      mpesaCode: code,
      title: title,
      category: _categoryFor(type, cleaned, isReceivedReversal: isReceivedReversal),
      amountKes: effectiveAmount,
      occurredAt: occurredAt,
      rawMessage: cleaned,
      transactionType: type,
      confidence: confidence,
      route: _routeFor(confidence),
      sourceHash: source,
      semanticHash: semanticHash(
        type: type,
        amountKes: effectiveAmount,
        occurredAt: occurredAt,
        title: title,
        mpesaCode: code,
      ),
      counterparty: counterparty,
      reason: reason,
      paybillAccount: _extractPaybillAccount(cleaned),
      balanceAfterKes: balanceAfterKes,
      feeKes: _extractFee(cleaned),
      isReceivedReversal: isReceivedReversal,
      fulizaOutstandingKes: _extractFulizaOutstanding(cleaned),
      fulizaAvailableLimitKes: _extractFulizaAvailableLimit(cleaned),
    );

    // Structural cross-check: a real (non-synthetic) 10-char code must appear
    // verbatim in the message. If not, the regex extracted something spurious.
    // Synthetic codes (SYN/FCHG/FREP prefixes) are derived from the message
    // hash and never appear verbatim — they are exempt.
    final isRealCode = code.length == 10 &&
        !code.startsWith('SYN') &&
        !code.startsWith('FCHG') &&
        !code.startsWith('FREP');
    if (isRealCode && !cleaned.toUpperCase().contains(code.toUpperCase())) {
      return _buildQuarantine(
        cleaned,
        reason: 'Structural mismatch: code not found in message',
        fallbackOccurredAt: fallbackOccurredAt,
      );
    }

    // Refine confidence with the weighted 6-factor scorer, then apply the
    // decision-tree second opinion to the *final* confidence value.
    //
    // Invariants neither stage may break:
    //   1. Unknown transaction types always stay quarantined (no upgrade).
    //   2. Fuliza types are identified by unambiguous keywords — their type
    //      recognition IS the confidence signal, so no scorer/tree adjustment.
    //   3. Sender-aware downgrades are authoritative — a non-MPESA sender
    //      deliberately reduces trust, so the scorer must not re-upgrade.
    final adjustable =
        candidate.transactionType != MpesaTransactionType.unknown &&
        !_kFulizaTypes.contains(candidate.transactionType);
    if (!adjustable) {
      return candidate;
    }

    final senderDowngraded =
        sender != null &&
        sender.isNotEmpty &&
        !sender.toLowerCase().contains('mpesa');

    var finalConfidence = candidate.confidence;

    // Stage 1 — weighted scorer.
    final scored = SmsConfidenceScorer().scoreTransaction(candidate: candidate);
    if (scored.confidence != candidate.confidence) {
      final wouldUpgrade =
          _kConfRank[scored.confidence]! > _kConfRank[candidate.confidence]!;
      // Sender-downgraded candidates may not be re-upgraded by the scorer.
      if (!(senderDowngraded && wouldUpgrade)) {
        finalConfidence = scored.confidence;
      }
    }

    // Stage 2 — decision-tree second opinion on the final confidence. If the
    // tree sees no reliable signals (tree=LOW) while confidence is still HIGH,
    // demote to review. The tree never upgrades — parser/scorer win on that.
    //
    // Structurally unambiguous types (airtime, deposit, withdrawal, Fuliza
    // charge) are exempt: their classification comes from a distinctive
    // keyword + amount, not from a transaction code or date corroboration, so
    // the tree's signal tests would spuriously demote perfectly good entries
    // to the review queue.
    final isStructurallyClear = switch (candidate.transactionType) {
      MpesaTransactionType.airtime ||
      MpesaTransactionType.deposit ||
      MpesaTransactionType.withdrawal ||
      MpesaTransactionType.fulizaCharge => true,
      _ => false,
    };
    if (!isStructurallyClear &&
        _decisionTree.shouldDemote(cleaned, finalConfidence)) {
      finalConfidence = MpesaConfidence.medium;
    }

    if (finalConfidence != candidate.confidence) {
      return candidate.copyWith(
        confidence: finalConfidence,
        route: _routeFor(finalConfidence),
      );
    }
    return candidate;
  }

  static const Set<MpesaTransactionType> _kFulizaTypes = {
    MpesaTransactionType.fulizaDraw,
    MpesaTransactionType.fulizaRepayment,
    MpesaTransactionType.fulizaCharge,
  };

  static const Map<MpesaConfidence, int> _kConfRank = {
    MpesaConfidence.high: 2,
    MpesaConfidence.medium: 1,
    MpesaConfidence.low: 0,
  };

  String sourceHash(String message) =>
      sha256.convert(utf8.encode(normalizeParserText(message))).toString();

  String semanticHash({
    required MpesaTransactionType type,
    required double amountKes,
    required DateTime occurredAt,
    required String title,
    String? mpesaCode,
  }) {
    // When an M-Pesa code is present it is the canonical transaction identity.
    if (mpesaCode != null &&
        mpesaCode.isNotEmpty &&
        mpesaCode != 'UNKNOWN' &&
        !mpesaCode.startsWith('SYN') &&
        !mpesaCode.startsWith('FCHG')) {
      return sha256.convert(utf8.encode('mpesa|$mpesaCode')).toString();
    }
    final key =
        '${type.name}|${amountKes.toStringAsFixed(2)}|${occurredAt.year}-${occurredAt.month}-${occurredAt.day}|${title.toLowerCase()}';
    return sha256.convert(utf8.encode(key)).toString();
  }

  ParsedMpesaCandidate _buildQuarantine(
    String cleaned, {
    required String reason,
    DateTime? fallbackOccurredAt,
  }) {
    final occurredAt = fallbackOccurredAt ?? DateTime.now();
    return ParsedMpesaCandidate(
      mpesaCode: 'UNKNOWN',
      title: 'Unclassified MPESA Message',
      category: 'Other',
      amountKes: 0,
      occurredAt: occurredAt,
      rawMessage: cleaned,
      transactionType: MpesaTransactionType.unknown,
      confidence: MpesaConfidence.low,
      route: MpesaParseRoute.quarantine,
      sourceHash: sourceHash(cleaned),
      semanticHash: semanticHash(
        type: MpesaTransactionType.unknown,
        amountKes: 0,
        occurredAt: occurredAt,
        title: 'unknown',
      ),
      reason: reason,
    );
  }

  (MpesaTransactionType, MpesaConfidence, String) _detect(
    String message, {
    String? sender,
  }) =>
      detectMpesaTransaction(message, sender: sender);

  MpesaParseRoute _routeFor(MpesaConfidence confidence) => switch (confidence) {
    MpesaConfidence.high => MpesaParseRoute.directLedger,
    MpesaConfidence.medium => MpesaParseRoute.reviewQueue,
    MpesaConfidence.low => MpesaParseRoute.quarantine,
  };

  String _categoryFor(
    MpesaTransactionType type,
    String message, {
    bool isReceivedReversal = false,
  }) => switch (type) {
    MpesaTransactionType.received => 'Income',
    MpesaTransactionType.paybill => 'Bills',
    MpesaTransactionType.buyGoods => 'Shopping',
    MpesaTransactionType.withdrawal => 'Cash',
    MpesaTransactionType.deposit => 'Cash',
    MpesaTransactionType.airtime => 'Airtime',
    MpesaTransactionType.reversal =>
      _categoryForReversal(message, isReceivedReversal: isReceivedReversal),
    MpesaTransactionType.fulizaDraw => 'Loan',
    MpesaTransactionType.fulizaRepayment => 'Loan',
    MpesaTransactionType.fulizaCharge => 'Loan',
    MpesaTransactionType.unknown =>
      message.toLowerCase().contains('salary') ? 'Income' : 'Other',
    _ => 'Other',
  };

  String _categoryForReversal(
    String message, {
    bool isReceivedReversal = false,
  }) {
    if (isReceivedReversal) {
      // A received payment was reversed — net effect is an outgoing debit.
      return 'Other';
    }
    final normalized = message.toLowerCase();
    if (normalized.contains('sent to') || normalized.contains('paid to')) {
      // Reversal of an outgoing payment credits money back to the user.
      return 'Income';
    }
    return 'Other';
  }

  String? _extractCounterparty(String message, MpesaTransactionType type) {
    String? value;
    switch (type) {
      case MpesaTransactionType.sent:
      case MpesaTransactionType.paybill:
        // "sent to NAME" / "sent to BILLER for account …" first, then the
        // "customer transfer of … to NAME" / "paybill payment to BILLER"
        // fallback so the newer phrasings still get a counterparty.
        value = _sentToPattern.firstMatch(message)?.group(1)?.trim() ??
            _transferToPattern.firstMatch(message)?.group(1)?.trim();
      case MpesaTransactionType.received:
        value = _receivedFromPattern.firstMatch(message)?.group(1)?.trim();
      case MpesaTransactionType.buyGoods:
        value = _paidToPattern.firstMatch(message)?.group(1)?.trim();
      default:
        value = null;
    }
    return value == null || value.isEmpty
        ? null
        : cleanCounterparty(titleCaseWords(value));
  }

  String _buildTitle(MpesaTransactionType type, String? counterparty) {
    if (counterparty != null) {
      return cleanCounterparty(counterparty);
    }
    return switch (type) {
      MpesaTransactionType.sent => 'MPESA Send',
      MpesaTransactionType.received => 'MPESA Receive',
      MpesaTransactionType.paybill => 'Paybill Payment',
      MpesaTransactionType.buyGoods => 'Buy Goods',
      MpesaTransactionType.withdrawal => 'Cash Withdrawal',
      MpesaTransactionType.deposit => 'Cash Deposit',
      MpesaTransactionType.airtime => 'Airtime Topup',
      MpesaTransactionType.reversal => 'MPESA Reversal',
      MpesaTransactionType.fulizaDraw => 'Fuliza Draw',
      MpesaTransactionType.fulizaRepayment => 'Fuliza Repayment',
      MpesaTransactionType.fulizaCharge => 'Fuliza Charge Notice',
      MpesaTransactionType.unknown => 'MPESA Transaction',
    };
  }

  String? _extractPaybillAccount(String message) =>
      _paybillPattern.firstMatch(message)?.group(1)?.trim();

  double? _extractBalanceAfter(String message) {
    final value = _balancePattern.firstMatch(message)?.group(1);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value.replaceAll(',', ''));
  }

  double? _extractFulizaOutstanding(String message) {
    final value = _fulizaOutstandingPattern.firstMatch(message)?.group(1);
    if (value == null) return null;
    return double.tryParse(value.replaceAll(',', ''));
  }

  double? _extractFulizaAvailableLimit(String message) {
    final value = _fulizaAvailableLimitPattern.firstMatch(message)?.group(1);
    if (value == null) return null;
    return double.tryParse(value.replaceAll(',', ''));
  }

  /// Trust codeless transaction variants only when they come from the official
  /// M-PESA sender and contain the minimum signals (amount + date). This lets
  /// through variants like "You have received Ksh..." that omit the usual
  /// 10-character code.
  bool _isTrustedCodelessTransaction(
    String message, {
    required MpesaTransactionType type,
    String? sender,
  }) {
    if (sender == null || !sender.toLowerCase().contains('mpesa')) {
      return false;
    }
    if (type == MpesaTransactionType.unknown ||
        type == MpesaTransactionType.fulizaCharge) {
      return false;
    }
    return _extractAmount(message) != null &&
        parseMpesaDateTime(message, _dateTimePattern) != null;
  }

  String? _extractMpesaCode(String message) {
    final match = _codePattern.firstMatch(message);
    if (match == null) return null;
    final code = match.group(1)!.toUpperCase();
    // Must contain at least one letter to exclude bare 10-digit phone numbers.
    // Safaricom 2026+ templates use all-letter codes (e.g. UCNDLAHMKE) — the
    // earlier digit requirement incorrectly quarantined every such transaction.
    if (!code.contains(RegExp(r'[A-Z]'))) return null;
    return code;
  }

  /// Extracts the 10-character M-Pesa transaction code from a raw message
  /// without doing a full parse. Returns `null` when no code is found.
  static String? extractMpesaCode(String message) {
    final normalized = normalizeParserText(message);
    final match = _codePattern.firstMatch(normalized);
    if (match == null) return null;
    final code = match.group(1)!.toUpperCase();
    if (!code.contains(RegExp(r'[A-Z]'))) return null;
    return code;
  }

  double? _extractAmount(String message) {
    final matches = _amountPattern.allMatches(message).toList();
    if (matches.isEmpty) return null;
    if (matches.length == 1) {
      return double.tryParse(matches.first.group(1)!.replaceAll(',', ''));
    }
    // Multiple amounts — pick the one closest to the first action verb.
    final verbMatch = _verbPattern.firstMatch(message);
    if (verbMatch != null) {
      final verbPos = verbMatch.start;
      final closest = matches.reduce(
        (a, b) =>
            (a.start - verbPos).abs() <= (b.start - verbPos).abs() ? a : b,
      );
      final value = closest.group(1);
      if (value != null) return double.tryParse(value.replaceAll(',', ''));
    }
    // Fallback: first occurrence.
    return double.tryParse(matches.first.group(1)!.replaceAll(',', ''));
  }

  double? _extractFee(String message) {
    final value = _feePattern.firstMatch(message)?.group(1);
    return value == null ? null : double.tryParse(value.replaceAll(',', ''));
  }
}

/// Top-level worker used by [Isolate.run]. Recreates the stateless parser
/// inside the isolate and applies the same fallback parse the main-thread
/// pipeline uses for queued messages.
List<ParsedMpesaCandidate> _parseJobsImpl(List<SmsParseJob> jobs) {
  const parser = MpesaParserService();
  final results = <ParsedMpesaCandidate>[];
  for (final job in jobs) {
    var parsed = parser.parseSingleDetailed(
      job.rawMessage,
      fallbackOccurredAt: job.fallbackOccurredAt,
      sender: job.sender,
    );
    // Only apply the "UNKNOWN Confirmed" fallback when the message isn't a
    // known-ignore (failed transaction, balance-only notice, etc.) — the
    // fallback prepends "Confirmed", which would otherwise defeat the ignore
    // filters and resurrect these as quarantined rows.
    if (parsed == null &&
        !shouldIgnoreMpesaSms(normalizeParserText(job.rawMessage))) {
      parsed = parser.parseSingleDetailed(
        'UNKNOWN Confirmed. Ksh0.00 ${job.rawMessage}',
        fallbackOccurredAt: job.fallbackOccurredAt,
        sender: job.sender,
      );
    }
    if (parsed != null) {
      results.add(parsed);
    }
  }
  return results;
}

/// Position-preserving variant of [_parseJobsImpl]: `result[i]` corresponds to
/// `jobs[i]` (or `null` when unparseable), so callers can zip results back to
/// their source rows by index safely.
List<ParsedMpesaCandidate?> _parseJobsAlignedImpl(List<SmsParseJob> jobs) {
  const parser = MpesaParserService();
  final results = List<ParsedMpesaCandidate?>.filled(jobs.length, null);
  for (var i = 0; i < jobs.length; i++) {
    final job = jobs[i];
    var parsed = parser.parseSingleDetailed(
      job.rawMessage,
      fallbackOccurredAt: job.fallbackOccurredAt,
      sender: job.sender,
    );
    // Skip the "UNKNOWN Confirmed" fallback for known-ignore messages (failed
    // transactions, balance-only notices) — it would resurrect them as
    // quarantined rows.
    if (parsed == null &&
        !shouldIgnoreMpesaSms(normalizeParserText(job.rawMessage))) {
      parsed = parser.parseSingleDetailed(
        'UNKNOWN Confirmed. Ksh0.00 ${job.rawMessage}',
        fallbackOccurredAt: job.fallbackOccurredAt,
        sender: job.sender,
      );
    }
    results[i] = parsed;
  }
  return results;
}
