import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/core/utils/legacy_seed_data.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/income/domain/repositories/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  IncomeRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<IncomeItem>> watchIncomes() {
    return _store.watchExpensesSnapshot().asyncMap((_) => _loadIncomes());
  }

  @override
  Future<void> addIncome({
    required String title,
    required double amountKes,
    DateTime? receivedAt,
    String source = 'manual',
  }) async {
    await _store.ensureInitialized();
    await _store.executor.runInsert(
      'INSERT INTO incomes(title, amount, received_at, source) VALUES (?, ?, ?, ?)',
      [
        title,
        amountKes,
        (receivedAt ?? DateTime.now()).millisecondsSinceEpoch,
        source
      ],
    );
    _store.emitChange();
  }

  @override
  Future<void> updateIncome({
    required int incomeId,
    required String title,
    required double amountKes,
    required DateTime receivedAt,
  }) async {
    await _store.ensureInitialized();
    await _store.executor.runUpdate(
      'UPDATE incomes SET title = ?, amount = ?, received_at = ?, source = ? WHERE id = ?',
      [title, amountKes, receivedAt.millisecondsSinceEpoch, 'manual', incomeId],
    );
    _store.emitChange();
  }

  @override
  Future<void> deleteIncome(int incomeId) async {
    await _store.ensureInitialized();
    await _store.executor
        .runDelete('DELETE FROM incomes WHERE id = ?', [incomeId]);
    _store.emitChange();
  }

  Future<List<IncomeItem>> _loadIncomes() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, title, amount, received_at, source FROM incomes ORDER BY received_at DESC, id DESC',
      const [],
    );
    return rows
        .map(
          (row) => IncomeItem(
            id: _asInt(row['id']),
            title: '${row['title'] ?? ''}',
            amountKes: _asDouble(row['amount']),
            receivedAt:
                DateTime.fromMillisecondsSinceEpoch(_asInt(row['received_at'])),
            source: '${row['source'] ?? 'manual'}',
          ),
        )
        .where(
          (item) => !isLegacySeedIncome(
            title: item.title,
            source: item.source,
          ),
        )
        .toList();
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
