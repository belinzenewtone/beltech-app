class FeeAnalytics {
  const FeeAnalytics({
    required this.totalFees,
    required this.feeCount,
    required this.monthlyFees,
    required this.averageFee,
    required this.topFeeCategories,
  });

  final double totalFees;
  final int feeCount;
  final List<MonthlyFee> monthlyFees;
  final double averageFee;
  final List<(String category, double amount)> topFeeCategories;
}

class MonthlyFee {
  const MonthlyFee({
    required this.year,
    required this.month,
    required this.total,
    required this.count,
  });

  final int year;
  final int month;
  final double total;
  final int count;
}
