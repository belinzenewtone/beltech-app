import 'package:beltech/core/utils/legacy_seed_data.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/domain/repositories/global_search_repository.dart';

class GlobalSearchRepositoryImpl implements GlobalSearchRepository {
  GlobalSearchRepositoryImpl(this._store);

  final AppDriftStore _store;

  @override
  Future<List<GlobalSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const [];
    }
    await _store.ensureInitialized();
    final pattern = '%${q.toLowerCase()}%';
    final results = <GlobalSearchResult>[];

    final expenses = await _store.executor.runSelect(
      'SELECT id, title, category, amount, source, occurred_at FROM transactions '
      'WHERE LOWER(title) LIKE ? OR LOWER(category) LIKE ? OR LOWER(source) LIKE ? OR LOWER(COALESCE(source_hash, \'\')) LIKE ? '
      'ORDER BY occurred_at DESC LIMIT 15',
      [pattern, pattern, pattern, pattern],
    );
    for (final row in expenses) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.expense,
          primaryText: '${row['title'] ?? ''}',
          secondaryText:
              '${row['category'] ?? 'Other'} · ${row['source'] ?? 'manual'}',
          trailingText: 'KES ${_asDouble(row['amount']).toStringAsFixed(2)}',
          recordId: _asInt(row['id']),
          recordDate: _asDate(row['occurred_at']),
        ),
      );
    }

    final incomes = await _store.executor.runSelect(
      'SELECT id, title, amount, source, received_at FROM incomes '
      'WHERE LOWER(title) LIKE ? OR LOWER(source) LIKE ? OR LOWER(CAST(amount AS TEXT)) LIKE ? '
      'ORDER BY received_at DESC LIMIT 15',
      [pattern, pattern, pattern],
    );
    for (final row in incomes) {
      final title = '${row['title'] ?? ''}';
      final source = '${row['source'] ?? 'manual'}';
      if (isLegacySeedIncome(title: title, source: source)) {
        continue;
      }
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.income,
          primaryText: title,
          secondaryText: source,
          trailingText: 'KES ${_asDouble(row['amount']).toStringAsFixed(2)}',
          recordId: _asInt(row['id']),
          recordDate: _asDate(row['received_at']),
        ),
      );
    }

    final tasks = await _store.executor.runSelect(
      'SELECT id, title, description, completed, priority, due_at FROM tasks '
      'WHERE LOWER(title) LIKE ? OR LOWER(COALESCE(description, \'\')) LIKE ? OR LOWER(priority) LIKE ? '
      'ORDER BY id DESC LIMIT 15',
      [pattern, pattern, pattern],
    );
    for (final row in tasks) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.task,
          primaryText: '${row['title'] ?? ''}',
          secondaryText:
              '${row['description'] ?? ''}${(row['description'] as String?)?.isNotEmpty == true ? ' · ' : ''}${row['priority'] ?? 'medium'}',
          trailingText: _asInt(row['completed']) == 1 ? 'Done' : 'Pending',
          recordId: _asInt(row['id']),
          recordDate: _asDate(row['due_at']),
        ),
      );
    }

    final events = await _store.executor.runSelect(
      'SELECT id, title, note, priority, start_at FROM events '
      'WHERE LOWER(title) LIKE ? OR LOWER(COALESCE(note, \'\')) LIKE ? OR LOWER(priority) LIKE ? '
      'ORDER BY start_at DESC LIMIT 15',
      [pattern, pattern, pattern],
    );
    for (final row in events) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.event,
          primaryText: '${row['title'] ?? ''}',
          secondaryText:
              '${row['note'] ?? ''}${(row['note'] as String?)?.isNotEmpty == true ? ' · ' : ''}${row['priority'] ?? 'medium'}',
          trailingText: 'Event',
          recordId: _asInt(row['id']),
          recordDate: _asDate(row['start_at']),
        ),
      );
    }

    final budgets = await _store.executor.runSelect(
      'SELECT id, category, monthly_limit FROM budgets WHERE LOWER(category) LIKE ? ORDER BY category LIMIT 15',
      [pattern],
    );
    for (final row in budgets) {
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.budget,
          primaryText: '${row['category'] ?? ''}',
          secondaryText: 'Monthly budget',
          trailingText:
              'KES ${_asDouble(row['monthly_limit']).toStringAsFixed(2)}',
          recordId: _asInt(row['id']),
        ),
      );
    }

    final recurring = await _store.executor.runSelect(
      'SELECT id, title, kind, cadence, description, category, next_run_at FROM recurring_templates '
      'WHERE LOWER(title) LIKE ? OR LOWER(COALESCE(description, \'\')) LIKE ? OR LOWER(COALESCE(category, \'\')) LIKE ? OR LOWER(kind) LIKE ? OR LOWER(cadence) LIKE ? '
      'ORDER BY id DESC LIMIT 15',
      [pattern, pattern, pattern, pattern, pattern],
    );
    for (final row in recurring) {
      final meta = [
        '${row['kind'] ?? ''}',
        '${row['cadence'] ?? ''}',
        '${row['category'] ?? ''}',
      ].where((value) => value.trim().isNotEmpty).join(' · ');
      results.add(
        GlobalSearchResult(
          kind: GlobalSearchKind.recurring,
          primaryText: '${row['title'] ?? ''}',
          secondaryText: meta,
          trailingText: '${row['description'] ?? ''}'.trim().isEmpty
              ? 'Recurring'
              : '${row['description']}',
          recordId: _asInt(row['id']),
          recordDate: _asDate(row['next_run_at']),
        ),
      );
    }

    return results;
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

  DateTime? _asDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    final parsedMs = int.tryParse('$value');
    if (parsedMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(parsedMs);
    }
    return DateTime.tryParse('$value');
  }
}
