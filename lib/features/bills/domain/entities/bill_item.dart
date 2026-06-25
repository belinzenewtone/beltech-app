class BillItem {
  const BillItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.urgency = BillUrgency.medium,
    this.recurrence,
    this.paid = false,
    required this.createdAt,
  });

  final int id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final BillUrgency urgency;
  final String? recurrence;
  final bool paid;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          amount == other.amount &&
          dueDate == other.dueDate &&
          urgency == other.urgency &&
          recurrence == other.recurrence &&
          paid == other.paid &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    dueDate,
    urgency,
    recurrence,
    paid,
    createdAt,
  );

  BillItem copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    BillUrgency? urgency,
    String? recurrence,
    bool? paid,
    DateTime? createdAt,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      urgency: urgency ?? this.urgency,
      recurrence: recurrence ?? this.recurrence,
      paid: paid ?? this.paid,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum BillUrgency { low, medium, high }

extension BillUrgencyLabel on BillUrgency {
  String get label => switch (this) {
    BillUrgency.low => 'Low',
    BillUrgency.medium => 'Medium',
    BillUrgency.high => 'High',
  };

  String get colorName => switch (this) {
    BillUrgency.low => 'accent',
    BillUrgency.medium => 'warning',
    BillUrgency.high => 'danger',
  };
}
