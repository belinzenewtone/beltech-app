part of 'notification_insights_service.dart';

extension _NotificationInsightsServiceReview on NotificationInsightsService {
  Future<void> _runWeeklyReviewRitual() async {
    if (!await _featureFlagStore.isEnabledFor(
      FeatureFlag.weeklyReviewRitual,
      userId: _accountRepository.currentSession().userId,
    )) {
      return;
    }
    if (!await isWeeklyReviewEnabled()) {
      return;
    }
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday || now.hour < 18) {
      return;
    }
    final expenses = await _readExpenses();
    if (expenses == null) {
      return;
    }
    final incomes = await _readIncomes();
    final tasks = await _readTasks();
    final analytics = await _readAnalytics();
    final upcomingEvents = await _readUpcomingEvents(now);
    final data = _buildWeekReviewDataUseCase(
      expenses: expenses,
      incomes: incomes,
      tasks: tasks,
      upcomingEventsCount: upcomingEvents.length,
      now: now,
    );
    final ritual = _buildWeekReviewRitualUseCase(data);
    final scope = _scope();
    final weekKey = _weekStart(now).toIso8601String().split('T').first;
    final notificationKey =
        '${NotificationInsightsService._weeklyReviewPrefix}.$scope.$weekKey';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(notificationKey) == true) {
      return;
    }
    final productivity = analytics?.productivityScore.round() ?? 0;
    final body =
        '${ritual.headline}. ${ritual.focusLabel}: ${ritual.focusDetail} '
        'Productivity $productivity%.';
    await _notifications.showInsight(
      insightId: notificationKey.hashCode.abs(),
      title: 'Weekly Review Ritual',
      body: body,
    );
    await _telemetryService.track(
      'weekly_review_notification_sent',
      attributes: {
        'scope': scope,
        'tone': ritual.tone.name,
        'pending_tasks': data.pendingCount,
        'productivity_band': _productivityBand(productivity.toDouble()),
      },
    );
    await prefs.setBool(notificationKey, true);
  }

  Future<List<IncomeItem>> _readIncomes() async {
    try {
      return await _incomeRepository.watchIncomes().first.timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      return const [];
    }
  }

  Future<AnalyticsSnapshot?> _readAnalytics() async {
    try {
      return await _analyticsRepository
          .watchSnapshot(AnalyticsPeriod.week)
          .first
          .timeout(
            const Duration(seconds: 8),
          );
    } catch (_) {
      return null;
    }
  }

  int _productivityBand(double productivity) {
    if (productivity >= 80) {
      return 3;
    }
    if (productivity >= 60) {
      return 2;
    }
    if (productivity > 0) {
      return 1;
    }
    return 0;
  }

  DateTime _weekStart(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return dayStart.subtract(Duration(days: dayStart.weekday - 1));
  }
}
