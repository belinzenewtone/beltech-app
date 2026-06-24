import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/budget/domain/entities/budget_target.dart';
import 'package:beltech/features/budget/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<BudgetSnapshot> watchMonthlySnapshot(DateTime month) {
    return _store.watchExpensesSnapshot().asyncMap((_) => _loadSnapshot(month));
  }

  @override
  Future<void> upsertTarget({
    required String category,
    required double monthlyLimitKes,
  }) async {
    await _store.ensureInitialized();
    final existing = await _store.executor.runSelect(
      'SELECT id FROM budgets WHERE LOWER(category) = LOWER(?) LIMIT 1',
      [category],
    );
    if (existing.isEmpty) {
      await _store.executor.runInsert(
        'INSERT INTO budgets(category, monthly_limit) VALUES (?, ?)',
        [category, monthlyLimitKes],
      );
    } else {
      await _store.executor.runUpdate(
        'UPDATE budgets SET monthly_limit = ?, category = ? WHERE id = ?',
        [monthlyLimitKes, category, _asInt(existing.first['id'])],
      );
    }
    _store.emitChange();
  }

  @override
  Future<void> deleteTarget(int targetId) async {
    await _store.ensureInitialized();
    await _store.executor
        .runDelete('DELETE FROM budgets WHERE id = ?', [targetId]);
    _store.emitChange();
  }

  @override
  Future<List<BudgetTarget>> loadTargets() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, category, monthly_limit FROM budgets ORDER BY category ASC',
      const [],
    );
    return rows
        .map(
          (row) => BudgetTarget(
            id: _asInt(row['id']),
            category: '${row['category'] ?? ''}',
            monthlyLimitKes: _asDouble(row['monthly_limit']),
          ),
        )
        .toList();
  }

  Future<BudgetSnapshot> _loadSnapshot(DateTime month) async {
    await _store.ensureInitialized();
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    final targets = await loadTargets();
    final rows = await _store.executor.runSelect(
      'SELECT category, COALESCE(SUM(amount), 0) AS total '
      'FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? '
      'GROUP BY category',
      [monthStart.millisecondsSinceEpoch, monthEnd.millisecondsSinceEpoch],
    );
    final spentByCategory = <String, double>{};
    for (final row in rows) {
      spentByCategory['${row['category'] ?? ''}'.toLowerCase()] =
          _asDouble(row['total']);
    }
    final items = targets
        .map(
          (target) => BudgetCategoryItem(
            category: target.category,
            monthlyLimitKes: target.monthlyLimitKes,
            spentKes: spentByCategory[target.category.toLowerCase()] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.spentKes.compareTo(a.spentKes));
    return BudgetSnapshot(month: monthStart, items: items);
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }
}
