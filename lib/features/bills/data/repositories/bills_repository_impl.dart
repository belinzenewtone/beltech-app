import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:beltech/features/bills/domain/repositories/bills_repository.dart';

class BillsRepositoryImpl implements BillsRepository {
  BillsRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<BillItem>> watchBills() {
    return _store.watchChangeStream().asyncMap((_) => loadBills());
  }

  @override
  Future<List<BillItem>> loadBills() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, name, amount, due_date, urgency, recurrence, paid, created_at '
      'FROM bills ORDER BY due_date ASC',
      const [],
    );
    return rows.map(_rowToBill).toList();
  }

  @override
  Future<void> upsertBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    BillUrgency urgency = BillUrgency.medium,
    String? recurrence,
    bool paid = false,
  }) async {
    await _store.ensureInitialized();
    await _store.executor.runInsert(
      'INSERT INTO bills(name, amount, due_date, urgency, recurrence, paid, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        name,
        amount,
        dueDate.millisecondsSinceEpoch,
        urgency.name,
        recurrence,
        paid ? 1 : 0,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    _store.emitChange();
  }

  @override
  Future<void> updateBill({
    required int id,
    String? name,
    double? amount,
    DateTime? dueDate,
    BillUrgency? urgency,
    String? recurrence,
    bool? paid,
  }) async {
    await _store.ensureInitialized();
    final sets = <String>[];
    final args = <Object?>[];
    if (name != null) {
      sets.add('name = ?');
      args.add(name);
    }
    if (amount != null) {
      sets.add('amount = ?');
      args.add(amount);
    }
    if (dueDate != null) {
      sets.add('due_date = ?');
      args.add(dueDate.millisecondsSinceEpoch);
    }
    if (urgency != null) {
      sets.add('urgency = ?');
      args.add(urgency.name);
    }
    if (recurrence != null) {
      sets.add('recurrence = ?');
      args.add(recurrence);
    }
    if (paid != null) {
      sets.add('paid = ?');
      args.add(paid ? 1 : 0);
    }
    if (sets.isEmpty) return;
    args.add(id);
    await _store.executor.runUpdate(
      'UPDATE bills SET ${sets.join(', ')} WHERE id = ?',
      args,
    );
    _store.emitChange();
  }

  @override
  Future<void> deleteBill(int id) async {
    await _store.ensureInitialized();
    await _store.executor.runDelete(
      'DELETE FROM bills WHERE id = ?',
      [id],
    );
    _store.emitChange();
  }

  @override
  Future<double> monthlyCommitmentTotal() async {
    await _store.ensureInitialized();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final rows = await _store.executor.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM bills '
      'WHERE paid = 0 AND due_date >= ? AND due_date < ?',
      [monthStart.millisecondsSinceEpoch, monthEnd.millisecondsSinceEpoch],
    );
    final value = rows.firstOrNull?['total'];
    return _asDouble(value);
  }

  @override
  Future<int> overdueCount() async {
    await _store.ensureInitialized();
    final now = DateTime.now();
    final rows = await _store.executor.runSelect(
      'SELECT COUNT(*) FROM bills WHERE paid = 0 AND due_date < ?',
      [now.millisecondsSinceEpoch],
    );
    return _asInt(rows.firstOrNull?['count']);
  }

  BillItem _rowToBill(Map<String, Object?> row) {
    return BillItem(
      id: _asInt(row['id']),
      name: '${row['name'] ?? ''}',
      amount: _asDouble(row['amount']),
      dueDate: DateTime.fromMillisecondsSinceEpoch(_asInt(row['due_date'])),
      urgency: BillUrgency.values.byName('${row['urgency'] ?? 'medium'}'),
      recurrence: row['recurrence'] as String?,
      paid: _asInt(row['paid']) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        _asInt(row['created_at']),
      ),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
