class LoanItem {
  const LoanItem({
    required this.id,
    required this.name,
    this.lender,
    required this.totalAmount,
    required this.outstandingAmount,
    this.interestRate,
    this.startDate,
    this.dueDate,
    this.status = LoanStatus.active,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? lender;
  final double totalAmount;
  final double outstandingAmount;
  final double? interestRate;
  final DateTime? startDate;
  final DateTime? dueDate;
  final LoanStatus status;
  final DateTime createdAt;

  double get progressPercent =>
      totalAmount > 0 ? (totalAmount - outstandingAmount) / totalAmount : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          outstandingAmount == other.outstandingAmount &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, name, outstandingAmount, status);
}

enum LoanStatus { active, cleared, defaulted }

extension LoanStatusLabel on LoanStatus {
  String get label => switch (this) {
    LoanStatus.active => 'Active',
    LoanStatus.cleared => 'Cleared',
    LoanStatus.defaulted => 'Defaulted',
  };
}
