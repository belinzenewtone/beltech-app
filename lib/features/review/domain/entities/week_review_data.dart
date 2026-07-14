/// Sentiment tone for a single derived insight.
enum WeekReviewInsightTone { positive, caution, neutral }

/// A single human-readable insight derived from the week's activity.
class WeekReviewInsight {
  const WeekReviewInsight({
    required this.title,
    required this.detail,
    required this.tone,
  });

  final String title;
  final String detail;
  final WeekReviewInsightTone tone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekReviewInsight &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          detail == other.detail &&
          tone == other.tone;

  @override
  int get hashCode => Object.hash(title, detail, tone);
}

/// Aggregated weekly summary derived from expenses, income, tasks, and events.
///
/// All monetary values are in KES.
class WeekReviewData {
  const WeekReviewData({
    required this.completedThisWeek,
    required this.pendingCount,
    required this.weeklySpendKes,
    required this.previousWeeklySpendKes,
    required this.weeklyIncomeKes,
    required this.previousWeeklyIncomeKes,
    required this.upcomingEventsCount,
    required this.tasksDueThisWeek,
    required this.tasksDueLastWeek,
    required this.completedLastWeek,
    required this.insights,
  });

  final int completedThisWeek;
  final int completedLastWeek;
  final int pendingCount;
  final int tasksDueThisWeek;
  final int tasksDueLastWeek;
  final double weeklySpendKes;
  final double previousWeeklySpendKes;
  final double weeklyIncomeKes;
  final double previousWeeklyIncomeKes;
  final int upcomingEventsCount;
  final List<WeekReviewInsight> insights;

  // ── Derived metrics ─────────────────────────────────────────────────────────

  double get netKes => weeklyIncomeKes - weeklySpendKes;
  double get previousNetKes => previousWeeklyIncomeKes - previousWeeklySpendKes;
  double get spendDeltaKes => weeklySpendKes - previousWeeklySpendKes;
  double get incomeDeltaKes => weeklyIncomeKes - previousWeeklyIncomeKes;
  double get netDeltaKes => netKes - previousNetKes;
  double get completionRateThisWeek =>
      tasksDueThisWeek == 0 ? 0 : completedThisWeek / tasksDueThisWeek;
  double get completionRateLastWeek =>
      tasksDueLastWeek == 0 ? 0 : completedLastWeek / tasksDueLastWeek;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekReviewData &&
          runtimeType == other.runtimeType &&
          completedThisWeek == other.completedThisWeek &&
          completedLastWeek == other.completedLastWeek &&
          pendingCount == other.pendingCount &&
          tasksDueThisWeek == other.tasksDueThisWeek &&
          tasksDueLastWeek == other.tasksDueLastWeek &&
          weeklySpendKes == other.weeklySpendKes &&
          previousWeeklySpendKes == other.previousWeeklySpendKes &&
          weeklyIncomeKes == other.weeklyIncomeKes &&
          previousWeeklyIncomeKes == other.previousWeeklyIncomeKes &&
          upcomingEventsCount == other.upcomingEventsCount &&
          _listEquals(insights, other.insights);

  @override
  int get hashCode => Object.hash(
    completedThisWeek,
    completedLastWeek,
    pendingCount,
    tasksDueThisWeek,
    tasksDueLastWeek,
    weeklySpendKes,
    previousWeeklySpendKes,
    weeklyIncomeKes,
    previousWeeklyIncomeKes,
    upcomingEventsCount,
    Object.hashAll(insights),
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
