import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';
import 'package:beltech/features/assistant/domain/ai_engine/offline_ai_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = OfflineAiEngine();

  group('OfflineAiEngine', () {
    test('replies to spending query', () async {
      final reply = await engine.reply(
        query: 'How much did I spend today?',
        totalBalance: Future.value(50000),
        todaySpending: Future.value(1500),
        weekSpending: Future.value(8000),
        monthSpending: Future.value(25000),
        monthIncome: Future.value(40000),
        pendingTasksCount: Future.value(3),
        overdueTasksCount: Future.value(0),
        weekEventsCount: Future.value(2),
        topCategories: Future.value(const [
          ('Food', 10000),
          ('Transport', 5000),
        ]),
        recentTransactions: Future.value(const []),
        billsUpcoming: Future.value(const []),
        billsOverdue: Future.value(const []),
        loansOutstanding: Future.value(0),
        loansActiveCount: Future.value(0),
        goals: Future.value(const []),
        learningStreak: Future.value(0),
        monthlyLearningMinutes: Future.value(0),
        avgDailyIncome: Future.value(1300),
        avgDailyExpense: Future.value(800),
        loanPayments: Future.value(const []),
      );
      expect(reply.contains('1,500'), true);
    });

    test('replies to health check', () async {
      final reply = await engine.reply(
        query: 'How is my financial health?',
        totalBalance: Future.value(50000),
        todaySpending: Future.value(0),
        weekSpending: Future.value(5000),
        monthSpending: Future.value(20000),
        monthIncome: Future.value(50000),
        pendingTasksCount: Future.value(0),
        overdueTasksCount: Future.value(0),
        weekEventsCount: Future.value(1),
        topCategories: Future.value(const []),
        recentTransactions: Future.value(const []),
        billsUpcoming: Future.value(const []),
        billsOverdue: Future.value(const []),
        loansOutstanding: Future.value(0),
        loansActiveCount: Future.value(0),
        goals: Future.value(const [
          GoalSummary(
            title: 'Save',
            target: 10000,
            current: 6000,
            progressPercent: 0.6,
            atRisk: false,
          ),
        ]),
        learningStreak: Future.value(10),
        monthlyLearningMinutes: Future.value(300),
        avgDailyIncome: Future.value(1600),
        avgDailyExpense: Future.value(650),
        loanPayments: Future.value(const []),
      );
      expect(reply.contains('score'), true);
      expect(reply.contains('/100'), true);
    });

    test('replies to anomaly query with no anomalies', () async {
      final reply = await engine.reply(
        query: 'Any anomalies?',
        totalBalance: Future.value(0),
        todaySpending: Future.value(0),
        weekSpending: Future.value(0),
        monthSpending: Future.value(0),
        monthIncome: Future.value(0),
        pendingTasksCount: Future.value(0),
        overdueTasksCount: Future.value(0),
        weekEventsCount: Future.value(0),
        topCategories: Future.value(const []),
        recentTransactions: Future.value(const []),
        billsUpcoming: Future.value(const []),
        billsOverdue: Future.value(const []),
        loansOutstanding: Future.value(0),
        loansActiveCount: Future.value(0),
        goals: Future.value(const []),
        learningStreak: Future.value(0),
        monthlyLearningMinutes: Future.value(0),
        avgDailyIncome: Future.value(0),
        avgDailyExpense: Future.value(0),
        loanPayments: Future.value(const []),
      );
      expect(reply.contains('No anomalies'), true);
    });

    test('replies to unknown query with fallback', () async {
      final reply = await engine.reply(
        query: 'Tell me a joke',
        totalBalance: Future.value(1000),
        todaySpending: Future.value(0),
        weekSpending: Future.value(0),
        monthSpending: Future.value(500),
        monthIncome: Future.value(1000),
        pendingTasksCount: Future.value(2),
        overdueTasksCount: Future.value(0),
        weekEventsCount: Future.value(0),
        topCategories: Future.value(const []),
        recentTransactions: Future.value(const []),
        billsUpcoming: Future.value(const []),
        billsOverdue: Future.value(const []),
        loansOutstanding: Future.value(0),
        loansActiveCount: Future.value(0),
        goals: Future.value(const []),
        learningStreak: Future.value(0),
        monthlyLearningMinutes: Future.value(0),
        avgDailyIncome: Future.value(30),
        avgDailyExpense: Future.value(15),
        loanPayments: Future.value(const []),
      );
      expect(reply.isNotEmpty, true);
      expect(reply.contains('not sure'), true);
    });
  });
}
