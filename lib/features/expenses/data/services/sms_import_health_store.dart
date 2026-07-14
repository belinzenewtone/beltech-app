/// A point-in-time snapshot of the SMS import pipeline health.
class ImportHealthSnapshot {
  final int totalOutcomes;
  final int phase1Hits;
  final int phase2Hits;
  final int phase3Hits;
  final int dedupHits;
  final int quarantineCount;
  final int successCount;
  final int failureCount;
  final Map<String, int> failureReasonCounts;

  const ImportHealthSnapshot({
    required this.totalOutcomes,
    required this.phase1Hits,
    required this.phase2Hits,
    required this.phase3Hits,
    required this.dedupHits,
    required this.quarantineCount,
    required this.successCount,
    required this.failureCount,
    required this.failureReasonCounts,
  });

  double get phase1Rate =>
      totalOutcomes == 0 ? 0 : phase1Hits / totalOutcomes;
  double get dedupRate =>
      totalOutcomes == 0 ? 0 : dedupHits / totalOutcomes;
  double get quarantineRate =>
      totalOutcomes == 0 ? 0 : quarantineCount / totalOutcomes;
}

/// Tracks pipeline outcomes in a fixed-size in-memory ring buffer.
///
/// Thread-unsafe — call only from the isolate / queue processing context.
/// The ring buffer holds [capacity] most-recent outcomes; older entries
/// are silently dropped.
class SmsImportHealthStore {
  SmsImportHealthStore({this.capacity = 200});

  final int capacity;

  // Ring buffer of raw outcome records.
  final List<_Outcome> _ring = [];

  void recordSuccess(int matchedRulePhase) {
    _add(_Outcome.success(matchedRulePhase));
  }

  void recordDuplicate() {
    _add(_Outcome.duplicate());
  }

  void recordQuarantine(String reason) {
    _add(_Outcome.quarantine(reason));
  }

  void recordFailure(String reason) {
    _add(_Outcome.failure(reason));
  }

  /// Snapshot of the current ring buffer.
  ImportHealthSnapshot snapshot() {
    int p1 = 0, p2 = 0, p3 = 0, dedup = 0, quarantine = 0, success = 0,
        failure = 0;
    final failureReasons = <String, int>{};

    for (final o in _ring) {
      switch (o.kind) {
        case _OutcomeKind.success:
          success++;
          if (o.matchedRulePhase == 1) p1++;
          if (o.matchedRulePhase == 2) p2++;
          if (o.matchedRulePhase == 3) p3++;
        case _OutcomeKind.duplicate:
          dedup++;
        case _OutcomeKind.quarantine:
          quarantine++;
          if (o.reason != null) {
            failureReasons[o.reason!] = (failureReasons[o.reason!] ?? 0) + 1;
          }
        case _OutcomeKind.failure:
          failure++;
          if (o.reason != null) {
            failureReasons[o.reason!] = (failureReasons[o.reason!] ?? 0) + 1;
          }
      }
    }

    return ImportHealthSnapshot(
      totalOutcomes: _ring.length,
      phase1Hits: p1,
      phase2Hits: p2,
      phase3Hits: p3,
      dedupHits: dedup,
      quarantineCount: quarantine,
      successCount: success,
      failureCount: failure,
      failureReasonCounts: Map.unmodifiable(failureReasons),
    );
  }

  void _add(_Outcome outcome) {
    if (_ring.length >= capacity) _ring.removeAt(0);
    _ring.add(outcome);
  }
}

// ── Internal record ────────────────────────────────────────────────────────────

enum _OutcomeKind { success, duplicate, quarantine, failure }

class _Outcome {
  final _OutcomeKind kind;
  final int matchedRulePhase;
  final String? reason;

  const _Outcome._({
    required this.kind,
    this.matchedRulePhase = 0,
    this.reason,
  });

  factory _Outcome.success(int phase) =>
      _Outcome._(kind: _OutcomeKind.success, matchedRulePhase: phase);

  factory _Outcome.duplicate() =>
      const _Outcome._(kind: _OutcomeKind.duplicate);

  factory _Outcome.quarantine(String reason) =>
      _Outcome._(kind: _OutcomeKind.quarantine, reason: reason);

  factory _Outcome.failure(String reason) =>
      _Outcome._(kind: _OutcomeKind.failure, reason: reason);
}
