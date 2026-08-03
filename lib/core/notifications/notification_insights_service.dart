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
    // Reflect the toggle immediately on the OS-scheduled digest reminder.
    await _notifications.scheduleDailyDigest();
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
    // Respect the user's Do-Not-Disturb window: WorkManager may invoke this at
    // any hour, but immediate insight notifications (budget alerts, weekly
    // review) must not wake the user during quiet hours.
    if (await _isInDoNotDisturbWindow()) {
      return;
    }
    // The daily spending summary is now delivered by an OS-scheduled repeating
    // reminder (LocalNotificationService.scheduleDailyDigest) so it fires on
    // time even when the app is killed — running it here too would double-fire.
    await _runBudgetThresholdAlerts();
    await _runWeeklyReviewRitual();
  }

  /// Returns true when the current time falls inside the user's configured
  /// quiet-hours window — immediate notifications must be suppressed.
  Future<bool> _isInDoNotDisturbWindow() async {
    final (startHour, endHour) = await _notifications.getDoNotDisturbHours();
    final h = DateTime.now().hour;
    if (startHour > endHour) {
      // Overnight window — e.g. 22:00 through 07:00.
      return h >= startHour || h < endHour;
    }
    // Same-day window — e.g. 09:00 through 18:00.
    return h >= startHour && h < endHour;
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

    // Read the user-configured "near limit" threshold (default 90 %).
    // Stages 2 (100 %) and 3 (120 %) remain fixed — they represent absolute
    // budget-exceeded milestones rather than a user preference.
    final (high, _, _) = await _notifications.getBudgetAlertThresholds();
    final nearLimitRatio = high / 100;

    for (final item in snapshot.items) {
      if (item.monthlyLimitKes <= 0) {
        continue;
      }
      final ratio = item.spentKes / item.monthlyLimitKes;
      final currentStage = _budgetStage(ratio, nearLimitRatio: nearLimitRatio);
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
        attributes: {'stage': currentStage, 'scope': scope},
      );
      await prefs.setInt(key, currentStage);
    }
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

  // Used by the weekly-review ritual (see the part file). The daily digest that
  // formerly shared these is now delivered by an OS-scheduled reminder.
  Future<ExpensesSnapshot?> _readExpenses() async {
    try {
      return await _expensesRepository.watchSnapshot().first.timeout(
        const Duration(seconds: 8),
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Expenses snapshot unavailable for notification sweep',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationInsights',
      );
      return null;
    }
  }

  Future<List<TaskItem>> _readTasks() async {
    try {
      return await _tasksRepository.watchTasks().first.timeout(
        const Duration(seconds: 8),
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Tasks unavailable for notification sweep',
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
          .watchEventsInRange(now, now.add(const Duration(hours: 24)))
          .first
          .timeout(const Duration(seconds: 8));
      return events.where((event) => !event.completed).toList();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Calendar events unavailable for notification sweep',
        error: error,
        stackTrace: stackTrace,
        tag: 'NotificationInsights',
      );
      return const [];
    }
  }


  int _budgetStage(double ratio, {double nearLimitRatio = 0.9}) {
    if (ratio >= 1.2) return 3; // exceeded
    if (ratio >= 1.0) return 2; // at limit
    if (ratio >= nearLimitRatio) return 1; // approaching (user-configurable)
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
