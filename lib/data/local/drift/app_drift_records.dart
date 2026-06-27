class DriftTransactionRecord {
  const DriftTransactionRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amountKes,
    required this.occurredAt,
    this.balanceAfterKes,
  });
  final int id;
  final String title;
  final String category;
  final double amountKes;
  final DateTime occurredAt;
  final double? balanceAfterKes;
}

class CategoryTotalRecord {
  const CategoryTotalRecord({required this.category, required this.totalKes});
  final String category;
  final double totalKes;
}

class HomeOverviewRecord {
  const HomeOverviewRecord({
    required this.todayKes,
    required this.weekKes,
    required this.completedCount,
    required this.pendingCount,
    required this.upcomingEventsCount,
    required this.weeklySpendingKes,
    required this.recentTransactions,
  });
  final double todayKes;
  final double weekKes;
  final int completedCount;
  final int pendingCount;
  final int upcomingEventsCount;
  final Map<String, double> weeklySpendingKes;
  final List<DriftTransactionRecord> recentTransactions;
}

class ExpensesSnapshotRecord {
  const ExpensesSnapshotRecord({
    required this.todayKes,
    required this.weekKes,
    required this.monthKes,
    required this.categories,
    required this.transactions,
  });
  final double todayKes;
  final double weekKes;
  final double monthKes;
  final List<CategoryTotalRecord> categories;
  final List<DriftTransactionRecord> transactions;
}

class DriftTaskRecord {
  const DriftTaskRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.reminderOffsets,
    required this.alarmEnabled,
    this.deadline,
    this.completedAt,
  });
  final int id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? deadline;
  final DateTime? completedAt;
  final List<int> reminderOffsets;
  final bool alarmEnabled;
}

class DriftEventRecord {
  const DriftEventRecord({
    required this.id,
    required this.title,
    required this.startAt,
    required this.completed,
    required this.priority,
    required this.eventType,
    required this.eventKind,
    required this.reminderOffsets,
    required this.alarmEnabled,
    this.endAt,
    this.note,
    this.allDay = false,
    this.repeatRule = 'never',
    this.guests = '',
    this.timeZoneId = '',
    this.reminderTimeOfDayMinutes = 480,
  });
  final int id;
  final String title;
  final DateTime startAt;
  final bool completed;
  final String priority;
  final String eventType;
  final String eventKind;
  final DateTime? endAt;
  final String? note;
  final List<int> reminderOffsets;
  final bool alarmEnabled;
  final bool allDay;
  final String repeatRule;
  final String guests;
  final String timeZoneId;
  final int reminderTimeOfDayMinutes;
}
