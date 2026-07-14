class HomeTransaction {
  const HomeTransaction({
    required this.title,
    required this.category,
    required this.amountKes,
  });

  final String title;
  final String category;
  final double amountKes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeTransaction &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          category == other.category &&
          amountKes == other.amountKes;

  @override
  int get hashCode => Object.hash(title, category, amountKes);
}

class HomeOverview {
  const HomeOverview({
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
  final List<HomeTransaction> recentTransactions;
}
