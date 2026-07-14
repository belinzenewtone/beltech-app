import 'dart:async';

import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';

/// Amount band assigned during import audit logging.
///
/// Bands follow Kenyan M-Pesa usage patterns:
///   - `lt100`   : micro-transactions, airtime, small payments (< Ksh 100)
///   - `k100_999`: everyday purchases (Ksh 100–999)
///   - `k1k_9999`: mid-range bills / paybills (Ksh 1,000–9,999)
///   - `k10kPlus`: large transfers, rent, salary (Ksh 10,000+)
enum AmountBand {
  lt100,
  k100_999,
  k1k_9999,
  k10kPlus;

  static AmountBand from(double amountKes) {
    if (amountKes < 100) return lt100;
    if (amountKes < 1000) return k100_999;
    if (amountKes < 10000) return k1k_9999;
    return k10kPlus;
  }
}

/// A single entry in the import audit log.
class AuditEntry {
  const AuditEntry({
    required this.sourceHash,
    required this.route,
    required this.confidence,
    required this.decision,
    required this.timestamp,
    this.reason,
    this.matchedRulePhase,
    this.amountBand,
  });

  final String sourceHash;
  final String route;
  final double confidence;
  final String decision;
  final String? reason;
  final DateTime timestamp;
  final int? matchedRulePhase;

  /// Amount band, present when [decision] is `'imported'` or `'review_pending'`.
  final AmountBand? amountBand;

  @override
  String toString() =>
      'AuditEntry($decision, route=$route, phase=$matchedRulePhase, '
      'confidence=${confidence.toStringAsFixed(2)}, band=$amountBand)';
}

/// In-memory audit logger that wraps a [ParseOutcome] into an [AuditEntry] and
/// emits it on [auditStream].
///
/// The persistent DB record is written by the import pipeline in
/// [ExpensesRepositoryImpl]; this logger adds a real-time stream on top so
/// the UI (e.g. import health screen) can react without polling.
class ImportAuditLogger {
  ImportAuditLogger._();

  static final ImportAuditLogger instance = ImportAuditLogger._();

  final StreamController<AuditEntry> _ctrl =
      StreamController<AuditEntry>.broadcast();

  /// Real-time stream of every audit entry as it is logged.
  Stream<AuditEntry> get auditStream => _ctrl.stream;

  /// Log a [ParseOutcome] produced for the message with [sourceHash].
  void log(ParseOutcome outcome, {required String sourceHash}) {
    if (_ctrl.isClosed) return;
    final entry = switch (outcome) {
      ParseSuccess(:final candidate) => AuditEntry(
        sourceHash: sourceHash,
        route: candidate.route.name,
        confidence: candidate.confidenceScore,
        decision: candidate.route == MpesaParseRoute.directLedger
            ? 'imported'
            : 'review_pending',
        reason: candidate.reason,
        timestamp: DateTime.now(),
        matchedRulePhase: candidate.matchedRulePhase,
        amountBand: AmountBand.from(candidate.amountKes),
      ),
      ParseDuplicate(:final dupeKey) => AuditEntry(
        sourceHash: sourceHash,
        route: 'duplicate',
        confidence: 0.0,
        decision: 'duplicate',
        reason: 'Duplicate of $dupeKey',
        timestamp: DateTime.now(),
      ),
      ParseFailure(:final reason, :final matchedRulePhase) => AuditEntry(
        sourceHash: sourceHash,
        route: 'quarantine',
        confidence: 0.0,
        decision: 'quarantined',
        reason: reason,
        timestamp: DateTime.now(),
        matchedRulePhase: matchedRulePhase,
      ),
      ParseFulizaUpdate(:final candidate) => AuditEntry(
        sourceHash: sourceHash,
        route: 'fuliza_update',
        confidence: candidate.confidenceScore,
        decision: 'fuliza_balance_update',
        reason: null,
        timestamp: DateTime.now(),
        matchedRulePhase: candidate.matchedRulePhase,
      ),
    };
    _ctrl.add(entry);
  }

  void dispose() => _ctrl.close();
}
