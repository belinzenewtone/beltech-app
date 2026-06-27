import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/recurring/data/services/recurring_suggestion_service.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = RecurringSuggestionService();

  ExpenseItem _tx(
    String title,
    double amount,
    DateTime date, {
    String category = 'Other',
  }) => ExpenseItem(
    id: 0,
    title: title,
    category: category,
    amountKes: amount,
    occurredAt: date,
  );

  test('detects monthly pattern from three occurrences', () {
    final base = DateTime(2025, 1, 15);
    final transactions = [
      _tx('Netflix', 1100, base, category: 'Entertainment'),
      _tx('Netflix', 1100, base.add(const Duration(days: 30)),
          category: 'Entertainment',),
      _tx('Netflix', 1100, base.add(const Duration(days: 60)),
          category: 'Entertainment',),
    ];

    final suggestions = service.detectSuggestions(transactions);
    expect(suggestions, hasLength(1));
    expect(suggestions.first.title, 'Netflix');
    expect(suggestions.first.cadence, RecurringCadence.monthly);
    expect(suggestions.first.amountKes, 1100);
  });

  test('detects weekly pattern', () {
    final base = DateTime(2025, 1, 6);
    final transactions = [
      _tx('Gym', 500, base),
      _tx('Gym', 500, base.add(const Duration(days: 7))),
      _tx('Gym', 500, base.add(const Duration(days: 14))),
      _tx('Gym', 500, base.add(const Duration(days: 21))),
    ];

    final suggestions = service.detectSuggestions(transactions);
    expect(suggestions, hasLength(1));
    expect(suggestions.first.cadence, RecurringCadence.weekly);
  });

  test('returns empty when pattern is irregular', () {
    final base = DateTime(2025, 1, 1);
    final transactions = [
      _tx('Random Shop', 200, base),
      _tx('Random Shop', 200, base.add(const Duration(days: 3))),
      _tx('Random Shop', 200, base.add(const Duration(days: 45))),
    ];

    final suggestions = service.detectSuggestions(transactions);
    expect(suggestions, isEmpty);
  });

  test('returns empty with fewer than two occurrences', () {
    final transactions = [
      _tx('Once Off', 1000, DateTime(2025, 1, 1)),
    ];

    final suggestions = service.detectSuggestions(transactions);
    expect(suggestions, isEmpty);
  });
}
