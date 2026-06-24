import 'dart:async';

import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/logger/app_logger.dart';
import 'package:beltech/core/telemetry/revamp_telemetry_service.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/budget/domain/repositories/budget_repository.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/income/domain/repositories/income_repository.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_data_use_case.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_ritual_use_case.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_notification_service.dart';

part 'notification_insights_service_review.dart';

class NotificationInsightsService {
  NotificationInsightsService(
    this._notifications,
    this._budgetRepository,
    this._expensesRepository,
    this._incomeRepository,
    this._tasksRepository,
    this._calendarRepository,
    this._analyticsRepository,
    this._accountRepository,
    this._buildWeekReviewDataUseCase,
    this._buildWeekReviewRitualUseCase,
    this._telemetryService,
    this._featureFlagStore,
  );

  static const String _budgetAlertsEnabledKey = 'notifications_budget_alerts';
  static const String _dailyDigestEnabledKey = 'notifications_daily_digest';
  static const String _weeklyReviewEnabledKey =
      'notifications_weekly_review_ritual';
  static const String _budgetStagePrefix = 'notification_budget_stage';
  static const String _dailyDigestPrefix = 'notification_daily_digest';
  static const String _weeklyReviewPrefix = 'notification_weekly_review';

  final LocalNotificationService _notifications;
  final BudgetRepository _budgetRepository;
  final ExpensesRepository _expensesRepository;
  final IncomeRepository _incomeRepository;
  final TasksRepository _tasksRepository;
  final CalendarRepository _calendarRepository;
  final AnalyticsRepository _analyticsRepository;
  final AccountRepository _accountRepository;
  final BuildWeekReviewDataUseCase _buildWeekReviewDataUseCase;
  final BuildWeekReviewRitualUseCase _buildWeekReviewRitualUseCase;
  final RevampTelemetryService _telemetryService;
  final FeatureFlagStore _featureFlagStore;

  Future<bool> isBudgetAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_budgetAlertsEnabledKey) ?? true;
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_budgetAlertsEnabledKey, enabled);
  }

  Future<bool> isDailyDigestEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyDigestEnabledKey) ?? true;
  }

  Future<void> setDailyDigestEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyDigestEnabledKey, enabled);
  }

  Future<bool> isWeeklyReviewEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_weeklyReviewEnabledKey) ?? true;
  }

  Future<void> setWeeklyReviewEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weeklyReviewEnabledKey, enabled);
  }

  Future<void> runSweep() async {
    if (!await _notifications.isNotificationsEnabled()) {
      return;
    }
    await _runBudgetThresholdAlerts();
    await _runDailyDigest();
    await _runWeeklyReviewRitual();
  }

  Future<void> _runBudgetThresholdAlerts() async {
    if (!await isBudgetAlertsEnabled()) {
      return;
    }
    final snapshot = await _readBudgetSnapshot();
    if (snapshot == null || snapshot.items.isEmpty) {
      return;
    }
    final monthKey =
        '${snapshot.month.year}-${snapshot.month.month.toString().padLeft(2, '0')}';
    final scope = _scope();
    final prefs = await SharedPreferences.getInstance();

    for (final item in snapshot.items) {
      if (item.monthlyLimitKes <= 0) {
        continue;
      }
      final ratio = item.spentKes / item.monthlyLimitKes;
      final currentStage = _budgetStage(ratio);
      final key =
          '$_budgetStagePrefix.$scope.$monthKey.${item.category.toLowerCase()}';
      final previousStage = prefs.getInt(key) ?? 0;
      if (currentStage <= previousStage || currentStage == 0) {
        continue;
      }
      final percentage = (ratio * 100).toStringAsFixed(0);
      final title = switch (currentStage) {
        1 => 'Budget Near Limit',
        2 => 'Budget Limit Reached',
        _ => 'Budget Limit Exceeded',
      };
      final body =
          '${item.category}: ${CurrencyFormatter.money(item.spentKes)} used ($percentage% of ${CurrencyFormatter.money(item.monthlyLimitKes)}).';
      await _notifications.showInsight(
        insightId: key.hashCode.abs(),
        title: title,
        body: body,
      );
      await _telemetryService.track(
        'budget_alert_sent',
        attributes: {
          'stage': currentStage,
          'scope': scope,
        },
      );
      await prefs.setInt(key, currentStage);
    }
  }

  Future<void> _runDailyDigest() async {
    if (!await isDailyDigestEnabled()) {
      return;
    }
    final now = DateTime.now();
    if (now.hour < 7) {
      return;
    }
    final scope = _scope();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final digestKey = '$_dailyDigestPrefix.$scope.$dateKey';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(digestKey) == true) {
      return;
    }

    final expenses = await _readExpenses();
    final tasks = await _readTasks();
    final upcomingEvents = await _readUpcomingEvents(now);
    final pendingTasks = tasks.where((task) => !task.completed).length;

    final body =
        'Today: ${CurrencyFormatter.money(expenses?.todayKes ?? 0)} spent, '
        '$pendingTasks pending tasks, ${upcomingEvents.length} upcoming events.';
    await _notifications.showInsight(
      insightId: digestKey.hashCode.abs(),
      title: 'Daily Summary',
      body: body,
    );
    await _telemetryService.track(
      'daily_digest_sent',
      attributes: {
        'scope': scope,
        'pending_tasks': pendingTasks,
        'upcoming_events': upcomingEvents.length,
      },
    );
    await prefs.setBool(digestKey, true);
  }

  Future<BudgetSnapshot?> _readBudgetSnapshot() async {
    try {
      return await _budgetRepository
          .watchMonthlySnapshot(DateTime.now())
          .first
          .timeout(const Duration(seconds: 8));
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Budget snapshot unavailable for notification sweep',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationInsights',
      );
      return null;
    }
  }

  Future<ExpensesSnapshot?> _readExpenses() async {
    try {
      return await _expensesRepository
          .watchSnapshot()
          .first
          .timeout(const Duration(seconds: 8));
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Expenses snapshot unavailable for daily digest',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationInsights',
      );
      return null;
    }
  }

  Future<List<TaskItem>> _readTasks() async {
    try {
      return await _tasksRepository
          .watchTasks()
          .first
          .timeout(const Duration(seconds: 8));
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Tasks unavailable for daily digest',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationInsights',
      );
      return const [];
    }
  }

  Future<List<dynamic>> _readUpcomingEvents(DateTime now) async {
    try {
      final events = await _calendarRepository
          .watchEventsInRange(
            now,
            now.add(const Duration(hours: 24)),
          )
          .first
          .timeout(const Duration(seconds: 8));
      return events.where((event) => !event.completed).toList();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Calendar events unavailable for daily digest',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationInsights',
      );
      return const [];
    }
  }

  int _budgetStage(double ratio) {
    if (ratio >= 1.2) {
      return 3;
    }
    if (ratio >= 1.0) {
      return 2;
    }
    if (ratio >= 0.8) {
      return 1;
    }
    return 0;
  }

  String _scope() {
    final userId = _accountRepository.currentSession().userId;
    if (userId == null || userId.isEmpty) {
      return 'local';
    }
    return userId;
  }
}
