import 'dart:async';

import 'package:beltech/features/expenses/domain/entities/expense.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_rule.dart';
import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';

/// Service that materializes recurring transactions into actual expenses.
/// Runs hourly to check for due recurring rules and create expense entries.
class RecurringMaterializerService {
  RecurringMaterializerService(this._recurringRepository);

  final RecurringRepository _recurringRepository;
  Timer? _timer;

  /// Start periodic materialization at the specified interval.
  Future<void> start({Duration interval = const Duration(minutes: 5)}) async {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncNow());
  }

  /// Stop periodic materialization.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  /// Sync entry point called by background worker.
  /// Materializes due recurring expenses.
  Future<void> syncNow() async {
    try {
      await materializeDueRecurring();
    } catch (e) {
      // Log but don't throw - background worker should continue
    }
  }

  /// Materialize all due recurring rules into expenses.
  /// Returns the list of expenses created.
  Future<List<Expense>> materializeDueRecurring() async {
    final now = DateTime.now();
    final created = <Expense>[];

    // Fetch all active recurring rules
    final rules = await _recurringRepository.getActiveRecurringRules();

    for (final rule in rules) {
      // Check if rule is due (nextRunAt is in the past or today)
      if (rule.nextRunAt.isBefore(now) || _isSameDay(rule.nextRunAt, now)) {
        // Create expense from recurring rule
        final expense = _createExpenseFromRule(rule);
        created.add(expense);
        // TODO: Update rule's next run date in repository
      }
    }

    return created;
  }

  /// Create an Expense from a RecurringRule.
  Expense _createExpenseFromRule(RecurringRule rule) {
    final now = DateTime.now();
    return Expense(
      id: 'recurring_${rule.id}_${now.millisecondsSinceEpoch}',
      amount: rule.estimatedAmount ?? 0.0,
      merchant: rule.merchant,
      description: rule.name,
      occurredAt: now,
      category: rule.category,
      fee: rule.estimatedFee,
    );
  }

  /// Check if two DateTime objects represent the same calendar day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
