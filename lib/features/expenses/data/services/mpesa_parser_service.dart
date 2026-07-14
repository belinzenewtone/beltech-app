import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:beltech/features/expenses/data/services/category_inference_engine.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_filters.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_rules.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';
import 'package:beltech/features/expenses/data/services/sms_confidence_scorer.dart';
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

  /// Broadcast stream emitting `(done, total)` progress ticks from [parseMany]
  /// and [parseManyDetailed]. Subscribe before calling those methods to receive
  /// all ticks; the stream is shared across all listeners.
  static Stream<({int done, int total})> get importProgress =>
      _progressCtrl.stream;

  static final StreamController<({int done, int total})> _progressCtrl =
      StreamController.broadcast();

  // Matches a 9-10 char alphanumeric code with at least one digit (excludes
  // pure-alpha words). Anchored by word boundary, not start-of-string.
  static final RegExp _codePattern = RegExp(
    r'\b(?=[A-Za-z0-9]*\d)(?=[A-Za-z0-9]*[A-Za-z])([A-Za-z0-9]{9,10})\b',
  );
  // For amount disambiguation: all amounts, action verbs, and balance markers.
  static final RegExp _allAmountsRe = RegExp(
    r'(?:ksh|kes)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _actionVerbRe = RegExp(
    r'\b(?:sent|received|paid|withdrew|deposited|bought|transferred|given)\b',
    caseSensitive: false,
  );
  static final RegExp _balanceMarkerRe = RegExp(
    r'(?:new\s+m-?pesa\s+balance|available\s+balance|balance\s+is|outstanding\s+amount)',
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
    final total = messages.length;
    for (var i = 0; i < total; i++) {
      final parsed = parseSingleDetailed(messages[i]);
      if (parsed != null) results.add(parsed);
      _progressCtrl.add((done: i + 1, total: total));
    }
    return results;
  }

  /// Parses a list of [SmsParseJob]s off the main thread when the batch is
  /// large enough to justify isolate serialization overhead.
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
    final cleaned = normalizeParserText(message);
    if (cleaned.isEmpty ||
        !looksLikeMpesaMessage(cleaned) ||
        shouldIgnoreMpesaSms(cleaned) ||
        isAmbiguousSuccessReceipt(cleaned)) {
      return null;
    }

    // Detect type early so fulizaCharge can skip the transaction-code
    // requirement (charge notices carry no M-Pesa code).
    final (type, _, reason, matchedPhase, matchedRule) =
        _detect(cleaned, sender: sender);

    String? code = _extractMpesaCode(cleaned);
    if (code == null) {
      if (type == MpesaTransactionType.fulizaCharge ||
          _isTrustedCodelessTransaction(
            cleaned,
            type: type,
            sender: sender,
          )) {
        // Derive a synthetic identifier from the message hash.
        final hash = sourceHash(cleaned);
        final prefix = type == MpesaTransactionType.fulizaCharge
            ? 'FCHG'
            : 'SYN${type.name.substring(0, 3).toUpperCase()}';
        code = '$prefix${hash.substring(0, 10 - prefix.length).toUpperCase()}';
      } else {
        return _buildQuarantine(
          cleaned,
          reason: 'Missing MPESA code',
          fallbackOccurredAt: fallbackOccurredAt,
          matchedRulePhase: matchedPhase,
        );
      }
    }

    final amount = _pickTransactionAmount(cleaned);
    if (type != MpesaTransactionType.fulizaCharge &&
        (amount == null || amount <= 0)) {
      return _buildQuarantine(
        cleaned,
        reason: 'Missing amount',
        fallbackOccurredAt: fallbackOccurredAt,
        matchedRulePhase: matchedPhase,
      );
    }
    final effectiveAmount = amount ?? 0.0;

    final parsedDate = parseMpesaDateTime(cleaned);
    final hasDate = parsedDate != null;
    final occurredAt = parsedDate ?? fallbackOccurredAt ?? DateTime.now();
    final balanceAfterKes = _extractBalanceAfter(cleaned);

    final isReceivedReversal =
        type == MpesaTransactionType.reversal &&
        cleaned.toLowerCase().contains('received from');

    final counterparty = _extractCounterparty(cleaned, type, rule: matchedRule);
    final title = _buildTitle(type, counterparty);
    final source = sourceHash(cleaned);

    final senderTrust = SenderTrust.fromSender(sender);
    final scoredConfidence = SmsConfidenceScorer().score(
      hasRealCode: !code.startsWith('SYN') && !code.startsWith('FCHG'),
      hasAmount: effectiveAmount > 0,
      hasDate: hasDate,
      hasMerchant: counterparty != null,
      transactionType: type,
      senderTrust: senderTrust,
      matchedRulePhase: matchedPhase,
    );

    final category = _inferCategory(
      type: type,
      title: title,
      amountKes: effectiveAmount,
      cleaned: cleaned,
      isReceivedReversal: isReceivedReversal,
    );

    return ParsedMpesaCandidate(
      mpesaCode: code,
      title: title,
      category: category,
      amountKes: effectiveAmount,
      occurredAt: occurredAt,
      rawMessage: cleaned,
      transactionType: type,
      confidence: scoredConfidence,
      route: _routeFor(scoredConfidence),
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
      matchedRulePhase: matchedPhase,
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
    int matchedRulePhase = 0,
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
      matchedRulePhase: matchedRulePhase,
    );
  }

  (MpesaTransactionType, MpesaConfidence, String, int, MpesaParserRule?) _detect(
    String message, {
    String? sender,
  }) =>
      detectMpesaTransaction(message, sender: sender);

  MpesaParseRoute _routeFor(MpesaConfidence confidence) => switch (confidence) {
    MpesaConfidence.high => MpesaParseRoute.directLedger,
    MpesaConfidence.medium => MpesaParseRoute.reviewQueue,
    MpesaConfidence.low => MpesaParseRoute.quarantine,
  };

  /// Infers the category for a parsed transaction.
  ///
  /// For merchant-bearing types (paybill, buyGoods, sent, unknown) the
  /// [CategoryInferenceEngine] is tried first; the remaining types use
  /// hardcoded M-Pesa-kind categories so they are never overridden by
  /// keyword heuristics (e.g. "received" must always be 'Income').
  String _inferCategory({
    required MpesaTransactionType type,
    required String title,
    required double amountKes,
    required String cleaned,
    bool isReceivedReversal = false,
  }) {
    // Hardcoded kinds — do not let keyword engine override these.
    switch (type) {
      case MpesaTransactionType.received:
        return 'Income';
      case MpesaTransactionType.withdrawal:
        return 'Cash';
      case MpesaTransactionType.deposit:
        return 'Cash';
      case MpesaTransactionType.airtime:
        return 'Airtime';
      case MpesaTransactionType.fulizaDraw:
        return 'Loans & Credit';
      case MpesaTransactionType.fulizaRepayment:
        return 'Loans & Credit';
      case MpesaTransactionType.fulizaCharge:
        return 'Loans & Credit';
      case MpesaTransactionType.reversal:
        if (isReceivedReversal) return 'Other';
        final lower = cleaned.toLowerCase();
        return (lower.contains('sent to') || lower.contains('paid to'))
            ? 'Income'
            : 'Other';
      default:
        break;
    }
    // Merchant-bearing types: try the inference engine, then fallback.
    final normalized = normalizeMerchantName(title);
    final guess = const CategoryInferenceEngine().infer(
      title: normalized.isNotEmpty ? normalized : title,
      amountKes: amountKes,
    );
    if (guess != null) return guess.category;

    return switch (type) {
      MpesaTransactionType.paybill => 'Bills & Utilities',
      MpesaTransactionType.buyGoods => 'Shopping',
      MpesaTransactionType.sent => 'Transfer',
      MpesaTransactionType.unknown =>
        cleaned.toLowerCase().contains('salary') ? 'Income' : 'Other',
      _ => 'Other',
    };
  }

  String? _extractCounterparty(
    String message,
    MpesaTransactionType type, {
    MpesaParserRule? rule,
  }) {
    // Prefer the per-rule pattern baked into the matched rule (Phase 4 T1).
    if (rule?.counterpartyPattern != null) {
      final value =
          rule!.counterpartyPattern!.firstMatch(message)?.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return cleanCounterparty(titleCaseWords(value));
      }
    }
    // Fallback: type-based generic patterns.
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
    return _pickTransactionAmount(message) != null &&
        parseMpesaDateTime(message) != null;
  }

  String? _extractMpesaCode(String message) =>
      _codePattern.firstMatch(message)?.group(1);

  /// Extracts the leading 10-character M-Pesa transaction code from a raw
  /// message without doing a full parse. Returns `null` when no code is found.
  static String? extractMpesaCode(String message) =>
      _codePattern.firstMatch(normalizeParserText(message))?.group(1);

  /// Picks the transaction amount, not the fee or balance, from a message that
  /// may contain multiple Ksh figures. Action verb proximity determines which
  /// amount is the transaction amount; balance-marker amounts are excluded.
  double? _pickTransactionAmount(String text) {
    final all = _allAmountsRe.allMatches(text).toList();
    if (all.isEmpty) return null;
    if (all.length == 1) {
      return double.tryParse(all.first.group(1)!.replaceAll(',', ''));
    }

    // Exclude amounts that appear after a balance/outstanding marker.
    bool isAfterBalance(RegExpMatch m) =>
        _balanceMarkerRe.hasMatch(text.substring(0, m.start));

    final candidates = all.where((m) => !isAfterBalance(m)).toList();
    final pool = candidates.isEmpty ? all : candidates;

    final verb = _actionVerbRe.firstMatch(text);
    if (verb == null) {
      // No action verb — return the largest non-balance amount.
      return pool
          .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')))
          .whereType<double>()
          .fold<double?>(null, (best, v) => best == null || v > best ? v : best);
    }

    // Return the amount whose start index is closest to the action verb.
    ({int dist, double val})? best;
    for (final m in pool) {
      final val = double.tryParse(m.group(1)!.replaceAll(',', ''));
      if (val == null) continue;
      final dist = (m.start - verb.start).abs();
      if (best == null || dist < best.dist) best = (dist: dist, val: val);
    }
    return best?.val;
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
    parsed ??= parser.parseSingleDetailed(
      'UNKNOWN Confirmed. Ksh0.00 ${job.rawMessage}',
      fallbackOccurredAt: job.fallbackOccurredAt,
      sender: job.sender,
    );
    if (parsed != null) {
      results.add(parsed);
    }
  }
  return results;
}
