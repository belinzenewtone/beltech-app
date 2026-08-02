import 'dart:convert';

import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_text.dart';
import 'package:crypto/crypto.dart';

/// Parser for Airtel Money Kenya SMS (Phase P5).
///
/// Airtel Money uses `KES` (never `Ksh`) and `AIR`-prefixed transaction IDs.
/// Ported from the Kotlin reference `AirtelMoneyParser`. Produces the shared
/// [ParsedMpesaCandidate] so it flows through the same dedup/route/persist
/// pipeline as M-Pesa and bank results.
class AirtelMoneyParser {
  const AirtelMoneyParser();

  static final RegExp _amount =
      RegExp(r'kes\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
  static final RegExp _ref = RegExp(
    r'(?:transaction\s*id|txn\s*id|trans\s*id)[:\s#]+(air[0-9]{5,15})',
    caseSensitive: false,
  );
  static final RegExp _balance = RegExp(
    r'(?:new\s+)?balance\s+(?:is\s+)?kes\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _fee = RegExp(
    r'charges?[:\s]+kes\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _from = RegExp(
    r"\bfrom\s+([a-z][a-z0-9 .\-']{1,35}?)(?:\s*\(|(?:\s+on\s+\d)|\.)",
    caseSensitive: false,
  );
  static final RegExp _to = RegExp(
    r"\bto\s+([a-z][a-z0-9 .\-']{1,35}?)(?:\s*\(|(?:\s+on\s+\d)|\.)",
    caseSensitive: false,
  );
  static final RegExp _credit =
      RegExp(r'\b(?:received?|credited?|deposit)\b', caseSensitive: false);
  static final RegExp _debit = RegExp(
    r'\b(?:sent|paid|payment|withdraw[an]l?)\b',
    caseSensitive: false,
  );
  static final RegExp _withdraw = RegExp(
    r'\b(?:withdraw[an]l?|cash\s*out|atm)\b',
    caseSensitive: false,
  );
  static final RegExp _paybill = RegExp(
    r'\b(?:paid\s+to|merchant|paybill|buy\s+goods)\b',
    caseSensitive: false,
  );
  static final RegExp _airtime =
      RegExp(r'\b(?:airtime|data\s+bundle)\b', caseSensitive: false);

  /// True when this looks like an Airtel Money SMS. Kept strict (sender,
  /// "airtel" keyword, or an explicit AIR transaction id) so it never steals
  /// M-Pesa/bank messages that merely contain the substring "air".
  bool canParse(String message, {String? sender}) {
    if (sender != null && sender.toUpperCase().contains('AIRTEL')) return true;
    // Require a strong Airtel signal — "airtel money" or an explicit AIR
    // transaction id. A bare "airtel" substring would wrongly steal a BANK SMS
    // that merely names an Airtel biller (e.g. "KCB … paid KES 500 to AIRTEL
    // SHOP"), which is dispatched before the bank parser is consulted.
    if (message.toLowerCase().contains('airtel money')) return true;
    return _ref.hasMatch(message);
  }

  ParsedMpesaCandidate? tryParse(
    String message, {
    String? sender,
    DateTime? fallbackOccurredAt,
  }) {
    if (!canParse(message, sender: sender)) return null;

    final normalized = normalizeParserText(message);
    final amount = _num(_amount.firstMatch(normalized)?.group(1));
    if (amount == null || amount <= 0) return null;

    final refRaw = _ref.firstMatch(normalized)?.group(1)?.toUpperCase();
    final balance = _num(_balance.firstMatch(normalized)?.group(1));
    final fee = _num(_fee.firstMatch(normalized)?.group(1));

    final isCredit = _credit.hasMatch(normalized);
    final isDebit = _debit.hasMatch(normalized);
    final isWithdraw = _withdraw.hasMatch(normalized);
    final isPaybill = _paybill.hasMatch(normalized);
    final isAirtime = _airtime.hasMatch(normalized);

    final type = isCredit && !isDebit
        ? MpesaTransactionType.received
        : isWithdraw
        ? MpesaTransactionType.withdrawal
        : isAirtime
        ? MpesaTransactionType.airtime
        : isPaybill
        ? MpesaTransactionType.paybill
        : isDebit
        ? MpesaTransactionType.sent
        : MpesaTransactionType.unknown;

    final counterparty = isCredit
        ? _from.firstMatch(normalized)?.group(1)?.trim()
        : isDebit
        ? _to.firstMatch(normalized)?.group(1)?.trim()
        : null;

    final confidence = (refRaw != null && (isCredit || isDebit))
        ? MpesaConfidence.high
        : (isCredit || isDebit)
        ? MpesaConfidence.medium
        : MpesaConfidence.low;
    final route = switch (confidence) {
      MpesaConfidence.high => MpesaParseRoute.directLedger,
      MpesaConfidence.medium => MpesaParseRoute.reviewQueue,
      MpesaConfidence.low => MpesaParseRoute.quarantine,
    };

    final occurredAt = fallbackOccurredAt ?? DateTime.now();
    final src = sha256.convert(utf8.encode(normalized)).toString();
    final sem = sha256
        .convert(
          utf8.encode(
            'airtel|${type.name}|$amount|'
            '${occurredAt.millisecondsSinceEpoch ~/ 60000}|${counterparty ?? ''}',
          ),
        )
        .toString();
    final code = refRaw ?? 'AIR${src.substring(0, 7).toUpperCase()}';

    return ParsedMpesaCandidate(
      mpesaCode: code,
      title: _describe(type, amount, counterparty),
      category: type == MpesaTransactionType.received ? 'Income' : 'Other',
      amountKes: amount,
      occurredAt: occurredAt,
      rawMessage: message,
      transactionType: type,
      confidence: confidence,
      route: route,
      sourceHash: src,
      semanticHash: sem,
      counterparty: counterparty,
      feeKes: fee,
      balanceAfterKes: balance,
      reason: 'Airtel Money',
    );
  }

  static double? _num(String? raw) =>
      raw == null ? null : double.tryParse(raw.replaceAll(',', ''));

  static String _describe(
    MpesaTransactionType type,
    double amount,
    String? counterparty,
  ) {
    final amt = 'KES ${amount.toStringAsFixed(2)}';
    final party = (counterparty != null && counterparty.isNotEmpty)
        ? ' ${type == MpesaTransactionType.received ? 'from' : 'to'} $counterparty'
        : '';
    return switch (type) {
      MpesaTransactionType.received => 'Airtel Money Received $amt$party',
      MpesaTransactionType.sent => 'Airtel Money Sent $amt$party',
      MpesaTransactionType.withdrawal => 'Airtel Money Withdrawal $amt',
      MpesaTransactionType.airtime => 'Airtel Airtime $amt',
      MpesaTransactionType.paybill => 'Airtel Money Payment $amt$party',
      _ => 'Airtel Money $amt',
    };
  }
}
