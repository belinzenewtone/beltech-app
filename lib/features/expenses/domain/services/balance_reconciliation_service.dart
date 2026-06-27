import 'package:beltech/data/local/drift/app_drift_store.dart';

/// Result of comparing consecutive SMS-reported M-PESA balances against the
/// transaction amounts recorded between them.
class BalanceReconciliationResult {
  const BalanceReconciliationResult({
    required this.occurredAt,
    required this.reportedDelta,
    required this.recordedDelta,
    required this.variance,
    required this.mpesaCode,
  });

  final DateTime occurredAt;
  final double reportedDelta;
  final double recordedDelta;
  final double variance;
  final String? mpesaCode;

  bool get hasDiscrepancy => variance.abs() > 1.0;
}

/// Lightweight balance reconciliation that flags missing or mis-recorded
/// transactions by comparing `balance_after` values from SMS.
class BalanceReconciliationService {
  const BalanceReconciliationService(this._store);

  final AppDriftStore _store;

  /// Returns transactions where the recorded amount does not match the change
  /// in reported M-PESA balance.
  Future<List<BalanceReconciliationResult>> reconcile({int limit = 20}) async {
    await _store.ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT amount, balance_after, occurred_at, transaction_type, source_hash '
      'FROM transactions '
      'WHERE balance_after IS NOT NULL AND source = ? '
      'ORDER BY occurred_at ASC',
      ['sms'],
    );

    if (rows.length < 2) return const [];

    final results = <BalanceReconciliationResult>[];
    double? previousBalance;
    DateTime? previousAt;

    for (final row in rows) {
      final balance = _asDouble(row['balance_after']);
      final occurredAt = DateTime.fromMillisecondsSinceEpoch(
        _asInt(row['occurred_at']),
      );
      final amount = _asDouble(row['amount']);
      final type = '${row['transaction_type'] ?? ''}';
      final signedAmount = _signedAmount(amount, type);

      if (previousBalance != null && previousAt != null) {
        final reportedDelta = balance - previousBalance;
        // The recorded delta between two balance points is the signed amount of
        // the later transaction. If multiple transactions happened between SMS
        // updates this is an approximation, but it catches obvious misses.
        final variance = reportedDelta - signedAmount;
        if (variance.abs() > 1.0) {
          results.add(
            BalanceReconciliationResult(
              occurredAt: occurredAt,
              reportedDelta: reportedDelta,
              recordedDelta: signedAmount,
              variance: variance,
              mpesaCode: _extractCode('${row['source_hash'] ?? ''}'),
            ),
          );
        }
      }

      previousBalance = balance;
      previousAt = occurredAt;
    }

    return results.take(limit).toList();
  }

  double _signedAmount(double amount, String type) {
    final outgoing = const {
      'sent',
      'paybill',
      'buyGoods',
      'withdrawal',
      'airtime',
      'fulizaDraw',
    };
    final incoming = const {'received', 'deposit', 'reversal'};
    if (outgoing.contains(type)) return -amount;
    if (incoming.contains(type)) return amount;
    return -amount;
  }

  String? _extractCode(String sourceHash) {
    // The source hash is a SHA-256 of the normalized message; we can't reverse
    // it to a human M-Pesa code, so return null for now.
    return null;
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
