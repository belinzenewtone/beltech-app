import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:beltech/features/income/domain/repositories/income_repository.dart';
import 'package:beltech/features/notifications/data/services/daily_digest_worker.dart';

/// Scheduler for daily digest notifications.
/// Runs once per day at a configured time to aggregate spending summary.
class DailyDigestScheduler {
  DailyDigestScheduler({
    required this.expensesRepository,
    required this.incomeRepository,
    required this.notificationService,
    this.scheduleTimeHour = 20, // 8 PM by default
  });

  final ExpensesRepository expensesRepository;
  final IncomeRepository incomeRepository;
  final LocalNotificationService notificationService;
  final int scheduleTimeHour;

  /// Check if digest should run today and generate/send if needed.
  Future<void> checkAndScheduleDaily() async {
    final lastRun = await _getLastRunDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Only run once per day
    if (lastRun != null) {
      final lastRunDay = DateTime(lastRun.year, lastRun.month, lastRun.day);
      if (lastRunDay == today) {
        return; // Already ran today
      }
    }

    // Generate digest
    final digest = await _generateDigest();
    if (digest != null) {
      // Send notification
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

      // Log run
      await _setLastRunDate(now);
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

      // Filter transactions by date (convert ExpenseItem to Expense-like structure)
      final todaysExpenses = <ExpenseData>[];
      final yesterdaysExpenses = <ExpenseData>[];
      final thisWeekExpenses = <ExpenseData>[];

      for (final item in snapshot.transactions) {
        final txDay = DateTime(
          item.occurredAt.year,
          item.occurredAt.month,
          item.occurredAt.day,
        );

        final expense = ExpenseData(
          amount: item.amountKes,
          merchant: item.title,
          category: item.category ?? 'Other',
          date: item.occurredAt,
        );

        if (txDay == today) {
          todaysExpenses.add(expense);
        }
        if (txDay == yesterday) {
          yesterdaysExpenses.add(expense);
        }
        if (item.occurredAt.isAfter(weekAgo) && item.occurredAt.isBefore(tomorrow)) {
          thisWeekExpenses.add(expense);
        }
      }

      if (todaysExpenses.isEmpty) {
        return null;
      }

      final worker = DailyDigestWorker(null);
      // Convert to Expense-like for worker
      final digest = await worker.generateDailyDigest(
        todaysExpenses: [], // TODO: Convert ExpenseData to Expense
        yesterdaysExpenses: [],
        thisWeekExpenses: [],
      );

      return digest;
    } catch (e) {
      return null;
    }
  }

  /// Get last run date from preferences.
  Future<DateTime?> _getLastRunDate() async {
    // TODO: Implement with SharedPreferences
    return null;
  }

  /// Set last run date in preferences.
  Future<void> _setLastRunDate(DateTime date) async {
    // TODO: Implement with SharedPreferences
  }
}

/// Simplified expense data for digest calculation.
class ExpenseData {
  const ExpenseData({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.date,
  });

  final double amount;
  final String merchant;
  final String category;
  final DateTime date;
}
