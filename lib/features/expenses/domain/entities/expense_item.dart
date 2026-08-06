class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amountKes,
    required this.occurredAt,
    this.balanceAfterKes,
    this.feeKes,
    this.source = 'manual',
  });

  final int id;
  final String title;
  final String category;
  final double amountKes;
  final DateTime occurredAt;
  final double? balanceAfterKes;

  /// M-Pesa transaction cost / service charge (KES), if present in the SMS.
  final double? feeKes;

  /// Origin of the transaction — 'manual' for user-entered, anything else
  /// (e.g. 'mpesa_sms', 'csv') for detected / imported entries.
  final String source;

  bool get isImported => source != 'manual';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          category == other.category &&
          amountKes == other.amountKes &&
          occurredAt == other.occurredAt &&
          balanceAfterKes == other.balanceAfterKes &&
          feeKes == other.feeKes &&
          source == other.source;

  @override
  int get hashCode =>
      Object.hash(id, title, category, amountKes, occurredAt, balanceAfterKes, feeKes, source);
}

class CategoryExpenseTotal {
  const CategoryExpenseTotal({required this.category, required this.totalKes});

  final String category;
  final double totalKes;
}

class ExpensesSnapshot {
  const ExpensesSnapshot({
    required this.todayKes,
    required this.weekKes,
    required this.monthKes,
    required this.categories,
    required this.transactions,
  });

  final double todayKes;
  final double weekKes;
  final double monthKes;
  final List<CategoryExpenseTotal> categories;
  final List<ExpenseItem> transactions;
}
