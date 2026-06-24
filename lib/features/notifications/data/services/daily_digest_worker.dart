import 'package:beltech/features/expenses/domain/entities/expense.dart';

/// Daily digest aggregator that compiles spending summaries and sends notifications.
class DailyDigestWorker {
  const DailyDigestWorker();

  /// Generate a daily digest containing top insights, merchants, and trends.
  Future<DailyDigest> generateDailyDigest({
    required List<Expense> todaysExpenses,
    required List<Expense> yesterdaysExpenses,
    required List<Expense> thisWeekExpenses,
  }) async {
    final topSpenders = _calculateTopMerchants(todaysExpenses);
    final dailyTotal = _sumAmounts(todaysExpenses);
    final weeklyAverage = _sumAmounts(thisWeekExpenses) / 7;
    final dayOverDayChange = _calculateDayOverDayChange(
      todaysExpenses,
      yesterdaysExpenses,
    );

    return DailyDigest(
      date: DateTime.now(),
      totalSpent: dailyTotal,
      transactionCount: todaysExpenses.length,
      topMerchants: topSpenders,
      weeklyAverage: weeklyAverage,
      dayOverDayChangePercent: dayOverDayChange,
      notificationTitle: _buildTitle(dailyTotal),
      notificationBody: _buildBody(dailyTotal, topSpenders),
    );
  }

  /// Calculate top merchants by spending today.
  List<MerchantSummary> _calculateTopMerchants(List<Expense> expenses) {
    final merchantTotals = <String, double>{};
    for (final expense in expenses) {
      merchantTotals[expense.merchant] =
          (merchantTotals[expense.merchant] ?? 0.0) + expense.amount;
    }

    final sorted = merchantTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) {
      final percent = (e.value / _sumAmounts(expenses) * 100);
      return MerchantSummary(
        merchant: e.key,
        amount: e.value,
        percentOfDay: percent,
      );
    }).toList();
  }

  /// Calculate day-over-day spending change percentage.
  double _calculateDayOverDayChange(
    List<Expense> today,
    List<Expense> yesterday,
  ) {
    final todayTotal = _sumAmounts(today);
    final yesterdayTotal = _sumAmounts(yesterday);

    if (yesterdayTotal == 0) return 0.0;

    return ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100;
  }

  /// Sum all expense amounts.
  double _sumAmounts(List<Expense> expenses) {
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Build notification title.
  String _buildTitle(double total) {
    return 'Daily Spending: KES ${total.toStringAsFixed(0)}';
  }

  /// Build notification body with top merchant.
  String _buildBody(double total, List<MerchantSummary> topMerchants) {
    if (topMerchants.isEmpty) {
      return 'No transactions today';
    }
    final top = topMerchants.first;
    return 'Top: ${top.merchant} (${top.percentOfDay.toStringAsFixed(0)}%)';
  }
}

/// Daily digest summary data.
class DailyDigest {
  const DailyDigest({
    required this.date,
    required this.totalSpent,
    required this.transactionCount,
    required this.topMerchants,
    required this.weeklyAverage,
    required this.dayOverDayChangePercent,
    required this.notificationTitle,
    required this.notificationBody,
  });

  final DateTime date;
  final double totalSpent;
  final int transactionCount;
  final List<MerchantSummary> topMerchants;
  final double weeklyAverage;
  final double dayOverDayChangePercent;
  final String notificationTitle;
  final String notificationBody;
}

/// Summary of spending at a single merchant.
class MerchantSummary {
  const MerchantSummary({
    required this.merchant,
    required this.amount,
    required this.percentOfDay,
  });

  final String merchant;
  final double amount;
  final double percentOfDay;
}
