class MerchantDetail {
  const MerchantDetail({
    required this.merchantTitle,
    required this.transactions,
    required this.totalSpent,
    required this.transactionCount,
    required this.firstSeen,
    required this.lastSeen,
    required this.averageAmount,
    required this.category,
  });

  final String merchantTitle;
  final List<MerchantTransaction> transactions;
  final double totalSpent;
  final int transactionCount;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final double averageAmount;
  final String category;

  double get monthlyAverage =>
      transactionCount > 0 ? totalSpent / _monthsSpan() : 0;

  int _monthsSpan() {
    final months =
        lastSeen.year * 12 +
        lastSeen.month -
        (firstSeen.year * 12 + firstSeen.month);
    return months <= 0 ? 1 : months + 1;
  }
}

class MerchantTransaction {
  const MerchantTransaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    this.balanceAfter,
  });

  final int id;
  final double amount;
  final DateTime date;
  final String category;
  final double? balanceAfter;
}
