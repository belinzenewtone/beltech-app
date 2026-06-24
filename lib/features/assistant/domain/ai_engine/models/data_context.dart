/// Aggregated local data used by the offline AI engine.
class DataContext {
  const DataContext({
    this.totalBalance = 0,
    this.todaySpending = 0,
    this.weekSpending = 0,
    this.monthSpending = 0,
    this.monthIncome = 0,
    this.pendingTasksCount = 0,
    this.overdueTasksCount = 0,
    this.weekEventsCount = 0,
    this.topCategories = const [],
    this.recentTransactions = const [],
    this.billsUpcoming = const [],
    this.billsOverdue = const [],
    this.loansOutstanding = 0,
    this.loansActiveCount = 0,
    this.goals = const [],
    this.learningStreak = 0,
    this.monthlyLearningMinutes = 0,
    this.healthScore = 50,
    this.anomalies = const [],
    this.cashFlowProjection = const [],
  });

  final double totalBalance;
  final double todaySpending;
  final double weekSpending;
  final double monthSpending;
  final double monthIncome;
  final int pendingTasksCount;
  final int overdueTasksCount;
  final int weekEventsCount;
  final List<(String category, double amount)> topCategories;
  final List<RecentTransaction> recentTransactions;
  final List<UpcomingBill> billsUpcoming;
  final List<UpcomingBill> billsOverdue;
  final double loansOutstanding;
  final int loansActiveCount;
  final List<GoalSummary> goals;
  final int learningStreak;
  final int monthlyLearningMinutes;
  final int healthScore;
  final List<Anomaly> anomalies;
  final List<CashFlowDay> cashFlowProjection;
}

class RecentTransaction {
  const RecentTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
  });

  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String type; // 'expense' | 'income'
}

class UpcomingBill {
  const UpcomingBill({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.daysUntil,
  });

  final String name;
  final double amount;
  final DateTime dueDate;
  final int daysUntil;
}

class GoalSummary {
  const GoalSummary({
    required this.title,
    required this.target,
    required this.current,
    required this.progressPercent,
    required this.atRisk,
  });

  final String title;
  final double target;
  final double current;
  final double progressPercent;
  final bool atRisk;
}

class Anomaly {
  const Anomaly({
    required this.type,
    required this.description,
    required this.severity,
  });

  final AnomalyType type;
  final String description;
  final AnomalySeverity severity;
}

enum AnomalyType { duplicate, unusualAmount, categorySpike, suspiciousMerchant, dailySurge }

enum AnomalySeverity { low, medium, high }

class CashFlowDay {
  const CashFlowDay({
    required this.date,
    required this.projectedBalance,
    required this.inflows,
    required this.outflows,
  });

  final DateTime date;
  final double projectedBalance;
  final double inflows;
  final double outflows;
}
