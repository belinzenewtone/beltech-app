part of 'expenses_repository_impl.dart';

Future<List<PaybillProfile>> _fetchPaybillProfilesImpl(
  ExpensesRepositoryImpl repo, {
  int limit = 10,
}) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT id, paybill, display_name, last_seen_at, usage_count '
    'FROM paybill_registry ORDER BY last_seen_at DESC LIMIT ?',
    [limit],
  );
  return rows
      .map(
        (row) => PaybillProfile(
          id: repo._asInt(row['id']),
          paybill: '${row['paybill'] ?? ''}',
          displayName: '${row['display_name'] ?? ''}',
          lastSeenAt: DateTime.fromMillisecondsSinceEpoch(
            repo._asInt(row['last_seen_at']),
          ),
          usageCount: repo._asInt(row['usage_count']),
        ),
      )
      .toList();
}

Future<List<FulizaLifecycleEvent>> _fetchFulizaLifecycleImpl(
  ExpensesRepositoryImpl repo, {
  int limit = 12,
}) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT id, mpesa_code, event_kind, amount, occurred_at '
    'FROM fuliza_lifecycle_events ORDER BY occurred_at DESC LIMIT ?',
    [limit],
  );
  return rows
      .map(
        (row) => FulizaLifecycleEvent(
          id: repo._asInt(row['id']),
          mpesaCode: '${row['mpesa_code'] ?? ''}',
          kind: '${row['event_kind'] ?? ''}' ==
                  MpesaTransactionType.fulizaDraw.name
              ? FulizaLifecycleKind.draw
              : FulizaLifecycleKind.repayment,
          amountKes: repo._asDouble(row['amount']),
          occurredAt: DateTime.fromMillisecondsSinceEpoch(
            repo._asInt(row['occurred_at']),
          ),
        ),
      )
      .toList();
}
