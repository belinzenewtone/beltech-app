import 'package:beltech/features/assistant/domain/ai_engine/cash_flow_projector.dart';
import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const projector = CashFlowProjector();

  group('CashFlowProjector', () {
    test('projects declining balance with bills', () {
      final now = DateTime.now();
      final projection = projector.project(
        currentBalance: 10000,
        avgDailyIncome: 500,
        avgDailyExpense: 300,
        upcomingBills: [
          UpcomingBill(name: 'Rent', amount: 5000, dueDate: now.add(const Duration(days: 5)), daysUntil: 5),
        ],
        loanPayments: [],
        days: 10,
      );
      expect(projection.length, 10);
      // Day 0: 10000 + 500 - 300 = 10200
      expect(projection.first.projectedBalance, closeTo(10200, 0.1));
      // Day 5 has the bill, so balance should drop
      final day5 = projection[5];
      expect(day5.outflows, closeTo(5300, 0.1)); // 300 + 5000
    });

    test('finds lowest point', () {
      final now = DateTime.now();
      final projection = projector.project(
        currentBalance: 1000,
        avgDailyIncome: 0,
        avgDailyExpense: 100,
        upcomingBills: [
          UpcomingBill(name: 'Big', amount: 500, dueDate: now.add(const Duration(days: 3)), daysUntil: 3),
        ],
        loanPayments: [],
        days: 7,
      );
      final (lowBal, lowDate) = projector.findLowestPoint(projection);
      expect(lowBal, lessThan(1000));
      expect(lowDate, isNotNull);
    });
  });
}
