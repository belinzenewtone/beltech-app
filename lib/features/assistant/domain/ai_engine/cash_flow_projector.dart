import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';

/// Projects cash flow for the next N days based on recurring patterns,
/// upcoming bills, and active loans.
class CashFlowProjector {
  const CashFlowProjector();

  List<CashFlowDay> project({
    required double currentBalance,
    required double avgDailyIncome,
    required double avgDailyExpense,
    required List<UpcomingBill> upcomingBills,
    required List<LoanPayment> loanPayments,
    int days = 30,
  }) {
    final projection = <CashFlowDay>[];
    var balance = currentBalance;
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      var inflows = avgDailyIncome;
      var outflows = avgDailyExpense;

      // Add bills due on this day
      for (final bill in upcomingBills) {
        if (_sameDay(bill.dueDate, date)) {
          outflows += bill.amount;
        }
      }

      // Add loan payments due on this day
      for (final payment in loanPayments) {
        if (_sameDay(payment.dueDate, date)) {
          outflows += payment.amount;
        }
      }

      balance = balance + inflows - outflows;
      projection.add(CashFlowDay(
        date: date,
        projectedBalance: balance,
        inflows: inflows,
        outflows: outflows,
      ));
    }

    return projection;
  }

  /// Returns the lowest projected balance and the date it occurs.
  (double lowestBalance, DateTime? date) findLowestPoint(List<CashFlowDay> projection) {
    if (projection.isEmpty) return (0, null);
    var lowest = projection.first;
    for (final day in projection) {
      if (day.projectedBalance < lowest.projectedBalance) {
        lowest = day;
      }
    }
    return (lowest.projectedBalance, lowest.date);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class LoanPayment {
  const LoanPayment({
    required this.loanName,
    required this.amount,
    required this.dueDate,
  });

  final String loanName;
  final double amount;
  final DateTime dueDate;
}
