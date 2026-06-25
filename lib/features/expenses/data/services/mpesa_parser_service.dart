import 'dart:convert';
import 'package:beltech/features/expenses/data/services/mpesa_parser_filters.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_rules.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';
import 'package:crypto/crypto.dart';

class MpesaParserService {
  const MpesaParserService();

  static final RegExp _codePattern = RegExp(r'^([A-Z0-9]{10})\b');
  static final RegExp _amountPattern = RegExp(
    r'(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
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
    r'(?:for\s+(?:account|acc(?:ount)?)(?:\s*(?:no\.?|number|#))?|account\s*(?:no\.?|number|#))\s*([a-z0-9-]{3,})',
    caseSensitive: false,
  );
  static final RegExp _sentToPattern = RegExp(
    r'sent to\s+([a-z0-9 .,&-]{3,}?)(?=\s+(?:for\s+(?:account|acc(?:ount)?)(?:\s*(?:no\.?|number|#))?|on)\b|[.]|$)',
    caseSensitive: false,
  );
  static final RegExp _receivedFromPattern = RegExp(
    r'received from\s+([a-z0-9 .,&-]{3,}?)(?=\s+on\b|[.]|$)',
    caseSensitive: false,
  );
  static final RegExp _paidToPattern = RegExp(
    r'paid to\s+([a-z0-9 .,&-]{3,}?)(?=\s+on\b|[.]|$)',
    caseSensitive: false,
  );

  // Fuliza-specific extraction patterns
  static final RegExp _fulizaOutstandingPattern = RegExp(
    r'total\s+fuliza[^.]*outstanding\s+amount\s+is\s+(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _fulizaAvailableLimitPattern = RegExp(
    r'available\s+fuliza[^.]*limit\s+is\s+(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
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
  }) {
    final cleaned = normalizeParserText(message);
    if (cleaned.isEmpty ||
        !looksLikeMpesaMessage(cleaned) ||
        shouldIgnoreMpesaSms(cleaned) ||
        isAmbiguousSuccessReceipt(cleaned)) {
      return null;
    }

    // Detect type early so fulizaCharge can skip the transaction-code
    // requirement (charge notices carry no M-Pesa code).
    final (type, confidence, reason) = _detect(cleaned);

    String? code = _extractMpesaCode(cleaned);
    if (code == null) {
      if (type == MpesaTransactionType.fulizaCharge) {
        // Derive a synthetic identifier from the message hash.
        final hash = sourceHash(cleaned);
        code = 'FCHG${hash.substring(0, 6).toUpperCase()}';
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

    return ParsedMpesaCandidate(
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
      ),
      counterparty: counterparty,
      reason: reason,
      paybillAccount: _extractPaybillAccount(cleaned),
      balanceAfterKes: balanceAfterKes,
      isReceivedReversal: isReceivedReversal,
      fulizaOutstandingKes: _extractFulizaOutstanding(cleaned),
      fulizaAvailableLimitKes: _extractFulizaAvailableLimit(cleaned),
    );
  }

  String sourceHash(String message) =>
      sha256.convert(utf8.encode(normalizeParserText(message))).toString();

  String semanticHash({
    required MpesaTransactionType type,
    required double amountKes,
    required DateTime occurredAt,
    required String title,
  }) {
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

  (MpesaTransactionType, MpesaConfidence, String) _detect(String message) =>
      detectMpesaTransaction(message);

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
    MpesaTransactionType.buyGoods => 'Food',
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
    final pattern = switch (type) {
      MpesaTransactionType.sent => _sentToPattern,
      MpesaTransactionType.received => _receivedFromPattern,
      MpesaTransactionType.paybill => _sentToPattern,
      MpesaTransactionType.buyGoods => _paidToPattern,
      _ => null,
    };
    final value = pattern?.firstMatch(message)?.group(1)?.trim();
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

  String? _extractMpesaCode(String message) =>
      _codePattern.firstMatch(message)?.group(1);

  /// Extracts the leading 10-character M-Pesa transaction code from a raw
  /// message without doing a full parse. Returns `null` when no code is found.
  static String? extractMpesaCode(String message) =>
      _codePattern.firstMatch(normalizeParserText(message))?.group(1);

  double? _extractAmount(String message) {
    final value = _amountPattern.firstMatch(message)?.group(1);
    return value == null ? null : double.tryParse(value.replaceAll(',', ''));
  }
}
