import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
import 'package:beltech/features/loans/domain/repositories/loans_repository.dart';

class LoansRepositoryImpl implements LoansRepository {
  LoansRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Stream<List<LoanItem>> watchLoans() {
    return _store.watchChangeStream().asyncMap((_) => loadLoans());
  }

  @override
  Future<List<LoanItem>> loadLoans() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, name, lender, total_amount, outstanding_amount, interest_rate, '
      'start_date, due_date, status, created_at FROM loans ORDER BY created_at DESC',
      const [],
    );
    return rows.map(_rowToLoan).toList();
  }

  @override
  Future<void> addLoan({
    required String name,
    String? lender,
    required double totalAmount,
    required double outstandingAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus status = LoanStatus.active,
  }) async {
    await _store.ensureInitialized();
    await _store.executor.runInsert(
      'INSERT INTO loans(name, lender, total_amount, outstanding_amount, interest_rate, '
      'start_date, due_date, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        name,
        lender,
        totalAmount,
        outstandingAmount,
        interestRate,
        startDate?.millisecondsSinceEpoch,
        dueDate?.millisecondsSinceEpoch,
        status.name,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    _store.emitChange();
  }

  @override
  Future<void> updateLoan({
    required int id,
    String? name,
    String? lender,
    double? totalAmount,
    double? outstandingAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus? status,
  }) async {
    await _store.ensureInitialized();
    final sets = <String>[];
    final args = <Object?>[];
    if (name != null) {
      sets.add('name = ?');
      args.add(name);
    }
    if (lender != null) {
      sets.add('lender = ?');
      args.add(lender);
    }
    if (totalAmount != null) {
      sets.add('total_amount = ?');
      args.add(totalAmount);
    }
    if (outstandingAmount != null) {
      sets.add('outstanding_amount = ?');
      args.add(outstandingAmount);
    }
    if (interestRate != null) {
      sets.add('interest_rate = ?');
      args.add(interestRate);
    }
    if (startDate != null) {
      sets.add('start_date = ?');
      args.add(startDate.millisecondsSinceEpoch);
    }
    if (dueDate != null) {
      sets.add('due_date = ?');
      args.add(dueDate.millisecondsSinceEpoch);
    }
    if (status != null) {
      sets.add('status = ?');
      args.add(status.name);
    }
    if (sets.isEmpty) return;
    args.add(id);
    await _store.executor.runUpdate(
      'UPDATE loans SET ${sets.join(', ')} WHERE id = ?',
      args,
    );
    _store.emitChange();
  }

  @override
  Future<void> deleteLoan(int id) async {
    await _store.ensureInitialized();
    await _store.executor.runDelete('DELETE FROM loans WHERE id = ?', [id]);
    _store.emitChange();
  }

  @override
  Future<double> totalOutstanding() async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT COALESCE(SUM(outstanding_amount), 0) AS total FROM loans WHERE status = ?',
      ['active'],
    );
    final value = rows.firstOrNull?['total'];
    return _asDouble(value);
  }

  LoanItem _rowToLoan(Map<String, Object?> row) {
    return LoanItem(
      id: _asInt(row['id']),
      name: '${row['name'] ?? ''}',
      lender: row['lender'] as String?,
      totalAmount: _asDouble(row['total_amount']),
      outstandingAmount: _asDouble(row['outstanding_amount']),
      interestRate: row['interest_rate'] != null
          ? _asDouble(row['interest_rate'])
          : null,
      startDate: row['start_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_asInt(row['start_date']))
          : null,
      dueDate: row['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_asInt(row['due_date']))
          : null,
      status: LoanStatus.values.byName('${row['status'] ?? 'active'}'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(_asInt(row['created_at'])),
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
