import 'package:beltech/features/expenses/domain/entities/expense.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_rule.dart';
import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';

/// Service that materializes recurring transactions into actual expenses.
/// Runs hourly to check for due recurring rules and create expense entries.
class RecurringMaterializerService {
  const RecurringMaterializerService(this._recurringRepository);

  final RecurringRepository _recurringRepository;

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

        // Update rule's next run date
        final nextRun = _calculateNextRun(rule, now);
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

  /// Calculate the next run date for a recurring rule based on its frequency.
  DateTime _calculateNextRun(RecurringRule rule, DateTime referenceDate) {
    switch (rule.frequency) {
      case RecurringFrequency.daily:
        return referenceDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return referenceDate.add(const Duration(days: 7));
      case RecurringFrequency.biweekly:
        return referenceDate.add(const Duration(days: 14));
      case RecurringFrequency.monthly:
        return _addMonths(referenceDate, 1);
      case RecurringFrequency.quarterly:
        return _addMonths(referenceDate, 3);
      case RecurringFrequency.annually:
        return _addMonths(referenceDate, 12);
    }
  }

  /// Check if two DateTime objects represent the same calendar day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Add months to a DateTime while handling month boundaries.
  DateTime _addMonths(DateTime date, int months) {
    var month = date.month + months;
    var year = date.year;
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    return DateTime(year, month, date.day);
  }
}

/// Frequency of recurring transactions.
enum RecurringFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  annually,
}
