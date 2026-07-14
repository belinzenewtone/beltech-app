import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:beltech/features/notifications/data/services/daily_digest_worker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Scheduler for daily digest notifications.
/// Runs once per day to aggregate spending summary.
class DailyDigestScheduler {
  DailyDigestScheduler({
    required this.expensesRepository,
    required this.notificationService,
  });

  final ExpensesRepository expensesRepository;
  final LocalNotificationService notificationService;

  /// Shared dedup key used by both digest implementations to prevent duplicate
  /// notifications on the same calendar day.
  static String _sharedDigestKey(DateTime day) =>
      'notification_digest_sent.'
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  /// Check if digest should run today and generate/send if needed.
  Future<void> checkAndScheduleDaily() async {
    final prefs = await SharedPreferences.getInstance();

    // Respect user preference (mirrors NotificationInsightsService key).
    if (!(prefs.getBool('notifications_daily_digest') ?? true)) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Shared dedup: bail if NotificationInsightsService already fired today.
    if (prefs.getBool(_sharedDigestKey(today)) == true) return;

    // Own last-run dedup.
    final lastRun = await _getLastRunDate();
    if (lastRun != null) {
      final lastRunDay = DateTime(lastRun.year, lastRun.month, lastRun.day);
      if (lastRunDay == today) return;
    }

    final digest = await _generateDigest();
    if (digest != null) {
      await notificationService.showNotification(
        id: 'daily_digest_${today.millisecondsSinceEpoch}',
        title: digest.notificationTitle,
        body: digest.notificationBody,
        payload: {
          'type': 'daily_digest',
          'date': today.toIso8601String(),
          'total': digest.totalSpent.toString(),
        },
      );
      await _setLastRunDate(now);
      // Mark shared key so NotificationInsightsService skips today.
      await prefs.setBool(_sharedDigestKey(today), true);
    }
  }

  /// Generate the daily digest from current data.
  Future<DailyDigest?> _generateDigest() async {
    try {
      final snapshot = await expensesRepository.watchSnapshot().first;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));
      final weekAgo = today.subtract(const Duration(days: 7));

      // Filter transactions by date and convert to Expense domain entities
      final todaysExpenses = <Expense>[];
      final yesterdaysExpenses = <Expense>[];
      final thisWeekExpenses = <Expense>[];

      for (final item in snapshot.transactions) {
        final txDay = DateTime(
          item.occurredAt.year,
          item.occurredAt.month,
          item.occurredAt.day,
        );

        final expense = Expense(
          id: 'digest_${item.id}_${today.millisecondsSinceEpoch}',
          amount: item.amountKes,
          merchant: item.title,
          description: item.title,
          occurredAt: item.occurredAt,
          category: item.category,
        );

        if (txDay == today) {
          todaysExpenses.add(expense);
        }
        if (txDay == yesterday) {
          yesterdaysExpenses.add(expense);
        }
        if (item.occurredAt.isAfter(weekAgo) &&
            item.occurredAt.isBefore(tomorrow)) {
          thisWeekExpenses.add(expense);
        }
      }

      if (todaysExpenses.isEmpty) {
        return null;
      }

      final worker = const DailyDigestWorker();
      final digest = await worker.generateDailyDigest(
        todaysExpenses: todaysExpenses,
        yesterdaysExpenses: yesterdaysExpenses,
        thisWeekExpenses: thisWeekExpenses,
      );

      return digest;
    } catch (e) {
      return null;
    }
  }

  /// Get last run date from preferences.
  Future<DateTime?> _getLastRunDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRunStr = prefs.getString('daily_digest_last_run');
      if (lastRunStr != null) {
        return DateTime.parse(lastRunStr);
      }
    } catch (_) {
      // Silently fail and return null
    }
    return null;
  }

  /// Set last run date in preferences.
  Future<void> _setLastRunDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('daily_digest_last_run', date.toIso8601String());
    } catch (_) {
      // Silently fail - not critical
    }
  }
}
