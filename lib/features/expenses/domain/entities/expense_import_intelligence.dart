class PaybillProfile {
  const PaybillProfile({
    required this.id,
    required this.paybill,
    required this.displayName,
    required this.lastSeenAt,
    required this.usageCount,
  });

  final int id;
  final String paybill;
  final String displayName;
  final DateTime lastSeenAt;
  final int usageCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaybillProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          paybill == other.paybill &&
          displayName == other.displayName &&
          lastSeenAt == other.lastSeenAt &&
          usageCount == other.usageCount;

  @override
  int get hashCode =>
      Object.hash(id, paybill, displayName, lastSeenAt, usageCount);
}

enum FulizaLifecycleKind { draw, repayment }

class FulizaLifecycleEvent {
  const FulizaLifecycleEvent({
    required this.id,
    required this.mpesaCode,
    required this.kind,
    required this.amountKes,
    required this.occurredAt,
  });

  final int id;
  final String mpesaCode;
  final FulizaLifecycleKind kind;
  final double amountKes;
  final DateTime occurredAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FulizaLifecycleEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mpesaCode == other.mpesaCode &&
          kind == other.kind &&
          amountKes == other.amountKes &&
          occurredAt == other.occurredAt;

  @override
  int get hashCode => Object.hash(id, mpesaCode, kind, amountKes, occurredAt);
}
