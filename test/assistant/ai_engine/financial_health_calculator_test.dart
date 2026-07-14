import 'package:beltech/features/assistant/domain/ai_engine/financial_health_calculator.dart';
import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = FinancialHealthCalculator();

  group('FinancialHealthCalculator', () {
    test('excellent health with high savings and no issues', () {
      final ctx = const DataContext(
        monthIncome: 100000,
        monthSpending: 50000,
        overdueTasksCount: 0,
        learningStreak: 10,
        goals: [
          GoalSummary(
            title: 'A',
            target: 1000,
            current: 600,
            progressPercent: 0.6,
            atRisk: false,
          ),
        ],
        billsOverdue: [],
        anomalies: [],
      );
      final score = calculator.calculate(ctx);
      expect(score, greaterThanOrEqualTo(80));
      expect(calculator.healthLabel(score), 'Excellent');
    });

    test('poor health with overspending and overdue tasks', () {
      final ctx = DataContext(
        monthIncome: 50000,
        monthSpending: 70000,
        overdueTasksCount: 5,
        learningStreak: 0,
        goals: const [],
        billsOverdue: [
          UpcomingBill(name: 'Rent', amount: 20000, dueDate: _d, daysUntil: -5),
        ],
        anomalies: [
          const Anomaly(
            type: AnomalyType.dailySurge,
            description: 'X',
            severity: AnomalySeverity.high,
          ),
        ],
        loansOutstanding: 200000,
      );
      final score = calculator.calculate(ctx);
      expect(score, lessThan(50));
      expect(calculator.healthLabel(score), 'Poor');
    });

    test(' clamps score between 0 and 100', () {
      final ctx = DataContext(
        monthIncome: 10000,
        monthSpending: 50000,
        overdueTasksCount: 20,
        billsOverdue: List.generate(
          10,
          (_) => UpcomingBill(name: 'X', amount: 1, dueDate: _d, daysUntil: -1),
        ),
        anomalies: List.generate(
          10,
          (_) => const Anomaly(
            type: AnomalyType.duplicate,
            description: 'X',
            severity: AnomalySeverity.high,
          ),
        ),
      );
      final score = calculator.calculate(ctx);
      expect(score, 0);
    });
  });
}

final _d = DateTime(2024, 1, 1);
