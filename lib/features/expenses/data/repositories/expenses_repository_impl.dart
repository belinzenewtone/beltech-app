import 'dart:convert';

import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/app_drift_store_mutations.dart';
import 'package:beltech/features/expenses/data/services/category_inference_engine.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/domain/entities/fee_analytics.dart';
import 'package:beltech/features/expenses/domain/entities/merchant_detail.dart';
import 'package:beltech/features/expenses/domain/entities/merchant_registry_entry.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';

part 'expenses_repository_impl_import_pipeline.dart';
part 'expenses_repository_impl_intelligence.dart';
part 'expenses_repository_impl_merchant_categories.dart';
part 'expenses_repository_impl_review.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  ExpensesRepositoryImpl(
    this._store,
    this._parser, [
    MerchantLearningService? merchantLearningService,
    DeviceSmsDataSource? deviceSmsDataSource,
  ]) : _merchantLearningService =
           merchantLearningService ?? MerchantLearningService(),
       _deviceSmsDataSource = deviceSmsDataSource ?? DeviceSmsDataSource();

  final AppDriftStore _store;
  final MpesaParserService _parser;
  final MerchantLearningService _merchantLearningService;
  final DeviceSmsDataSource _deviceSmsDataSource;

  @override
  Stream<ExpensesSnapshot> watchSnapshot() {
    return _store.watchExpensesSnapshot().map(
      (record) => ExpensesSnapshot(
        todayKes: record.todayKes,
        weekKes: record.weekKes,
        monthKes: record.monthKes,
        categories: record.categories
            .map(
              (item) => CategoryExpenseTotal(
                category: item.category,
                totalKes: item.totalKes,
              ),
            )
            .toList(),
        transactions: record.transactions
            .map(
              (tx) => ExpenseItem(
                id: tx.id,
                title: tx.title,
                category: tx.category,
                amountKes: tx.amountKes,
                occurredAt: tx.occurredAt,
                balanceAfterKes: tx.balanceAfterKes,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Future<void> addManualTransaction({
    required String title,
    required String category,
    required double amountKes,
    DateTime? occurredAt,
  }) async {
    await _learnMerchantCategoryImpl(
      this,
      merchantTitle: title,
      category: category,
    );
    await _store.addTransaction(
      title: title,
      category: category,
      amountKes: amountKes,
      occurredAt: occurredAt,
    );
  }

  @override
  Future<void> updateTransaction({
    required int transactionId,
    required String title,
    required String category,
    required double amountKes,
    required DateTime occurredAt,
  }) async {
    await _learnMerchantCategoryImpl(
      this,
      merchantTitle: title,
      category: category,
    );
    await _store.updateTransaction(
      id: transactionId,
      title: title,
      category: category,
      amountKes: amountKes,
      occurredAt: occurredAt,
    );
  }

  @override
  Future<void> deleteTransaction(int transactionId) {
    return _store.deleteTransaction(transactionId);
  }

  @override
  Future<int> importSmsMessages(
    List<String> rawMessages, {
    DateTime? from,
  }) async {
    final envelopes = rawMessages
        .map((message) => _QueuedSmsImport(message: message))
        .toList(growable: false);
    await _enqueueSmsImports(envelopes);
    return _processDueQueueImpl(this, from: from);
  }



  @override
  Future<int> importFromDevice({DateTime? from}) async {
    final entries = await _deviceSmsDataSource.loadLikelyMpesaEntries(
      from: from,
    );
    if (entries.isNotEmpty) {
      await _enqueueSmsImports(
        entries
            .map(
              (entry) => _QueuedSmsImport(
                message: entry.body,
                sourceTimestamp: entry.receivedAt,
                sender: entry.sender,
              ),
            )
            .toList(growable: false),
      );
    }
    return _processDueQueueImpl(this, from: from);
  }

  Future<void> _enqueueSmsImports(List<_QueuedSmsImport> envelopes) async {
    await _store.ensureInitialized();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Deduplicate within the incoming batch and build parse jobs.
    final jobs = <SmsParseJob>[];
    final rawByHash = <String, String>{};
    final sourceTimestampByHash = <String, DateTime?>{};
    for (final envelope in envelopes) {
      final message = envelope.message.trim();
      if (message.isEmpty) {
        continue;
      }
      final hash = _parser.sourceHash(message);
      rawByHash[hash] = message;
      sourceTimestampByHash[hash] = envelope.sourceTimestamp;
      jobs.add(
        SmsParseJob(
          message,
          fallbackOccurredAt: envelope.sourceTimestamp,
          sender: envelope.sender,
        ),
      );
    }
    if (jobs.isEmpty) {
      return;
    }

    // Parse once in an isolate for large batches; synchronously for small ones.
    final candidates = await MpesaParserService.parseJobsInIsolate(jobs);
    final candidateByHash = <String, ParsedMpesaCandidate>{};
    for (final candidate in candidates) {
      candidateByHash[candidate.sourceHash] = candidate;
    }

    final allHashes = rawByHash.keys.toList();
    final alreadyImported = await _existingSourceHashes(
      'transactions',
      allHashes,
    );
    final alreadyQueued = await _existingSourceHashes(
      'sms_import_queue',
      allHashes,
    );

    final insertRows = <List<Object?>>[];
    final refreshRows = <List<Object?>>[];

    for (final hash in rawByHash.keys) {
      // Skip messages that have already made it into the ledger.
      if (alreadyImported.contains(hash)) {
        continue;
      }

      final raw = rawByHash[hash]!;
      final sourceTimestamp = sourceTimestampByHash[hash];
      final candidate = candidateByHash[hash];
      final semanticHash = candidate?.semanticHash ?? hash;
      final route = candidate?.route.name ?? MpesaParseRoute.quarantine.name;
      final confidence = candidate?.confidenceScore ?? 0.0;
      final sourceTimestampMs = sourceTimestamp?.millisecondsSinceEpoch;

      refreshRows.add([
        raw,
        semanticHash,
        sourceTimestampMs,
        sourceTimestampMs,
        sourceTimestampMs,
        route,
        confidence,
        'retry',
        'failed',
        'pending',
        'retry',
        'failed',
        'retry',
        'failed',
        'retry',
        'failed',
        nowMs,
        'local',
        hash,
      ]);

      if (!alreadyQueued.contains(hash)) {
        insertRows.add([
          'local',
          raw,
          hash,
          semanticHash,
          sourceTimestampMs,
          'pending',
          route,
          confidence,
          nowMs,
          nowMs,
        ]);
      }
    }

    if (insertRows.isNotEmpty) {
      await _store.insertSmsImportQueueBatch(insertRows);
    }
    if (refreshRows.isNotEmpty) {
      await _store.refreshSmsImportQueueBatch(refreshRows);
    }
  }

  Future<Set<String>> _existingSourceHashes(
    String table,
    List<String> hashes,
  ) async {
    final result = <String>{};
    if (hashes.isEmpty) {
      return result;
    }
    const chunkSize = 500;
    for (var i = 0; i < hashes.length; i += chunkSize) {
      final chunk = hashes.sublist(
        i,
        (i + chunkSize).clamp(0, hashes.length),
      );
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await _store.executor.runSelect(
        'SELECT source_hash FROM $table WHERE source_hash IN ($placeholders)',
        chunk,
      );
      for (final row in rows) {
        final hash = '${row['source_hash']}';
        if (hash.isNotEmpty) {
          result.add(hash);
        }
      }
    }
    return result;
  }

  @override
  Future<ExpenseImportMetrics> fetchImportMetrics() =>
      _fetchImportMetricsImpl(this);

  @override
  Future<List<PaybillProfile>> fetchPaybillProfiles({int limit = 10}) =>
      _fetchPaybillProfilesImpl(this, limit: limit);

  @override
  Future<List<FulizaLifecycleEvent>> fetchFulizaLifecycle({int limit = 12}) =>
      _fetchFulizaLifecycleImpl(this, limit: limit);

  @override
  Future<List<ExpenseReviewItem>> fetchReviewQueue({int limit = 20}) =>
      _fetchReviewQueueImpl(this, limit: limit);

  @override
  Future<List<ExpenseQuarantineItem>> fetchQuarantineItems({int limit = 20}) =>
      _fetchQuarantineItemsImpl(this, limit: limit);

  @override
  Future<void> resolveReviewItem({
    required int reviewId,
    required bool approve,
  }) => _resolveReviewItemImpl(this, reviewId: reviewId, approve: approve);

  @override
  Future<void> dismissQuarantineItem(int quarantineId) =>
      _dismissQuarantineItemImpl(this, quarantineId);

  @override
  Future<void> approveQuarantineItem(int quarantineId) =>
      _approveQuarantineItemImpl(this, quarantineId);

  @override
  Future<void> rejectQuarantineItem(int quarantineId) =>
      _rejectQuarantineItemImpl(this, quarantineId);

  @override
  Future<void> updateAndApproveQuarantineItem({
    required int quarantineId,
    required String title,
    required double amountKes,
    String? category,
  }) => _updateAndApproveQuarantineItemImpl(
    this,
    quarantineId: quarantineId,
    title: title,
    amountKes: amountKes,
    category: category,
  );

  @override
  Future<int> replayImportQueue() => _replayImportQueueImpl(this);

  @override
  Future<MerchantDetail> fetchMerchantDetail(String merchantTitle) async {
    await _store.ensureInitialized();
    final normalized = _normalizeMerchantTitle(merchantTitle);
    final rows = await _store.executor.runSelect(
      "SELECT id, title, amount, occurred_at, category, balance_after FROM transactions WHERE LOWER(title) LIKE ? OR LOWER(title) = ? ORDER BY occurred_at DESC",
      ['%$normalized%', normalized],
    );
    if (rows.isEmpty) {
      return MerchantDetail(
        merchantTitle: merchantTitle,
        transactions: const [],
        totalSpent: 0,
        transactionCount: 0,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
        averageAmount: 0,
        category: '',
      );
    }
    final txs = rows
        .map(
          (r) => MerchantTransaction(
            id: _asInt(r['id']),
            amount: _asDouble(r['amount']),
            date: DateTime.fromMillisecondsSinceEpoch(_asInt(r['occurred_at'])),
            category: '${r['category'] ?? ''}',
            balanceAfter: r['balance_after'] != null
                ? _asDouble(r['balance_after'])
                : null,
          ),
        )
        .toList();
    final total = txs.fold<double>(0, (s, t) => s + t.amount);
    final categories = <String, int>{};
    for (final t in txs) {
      categories[t.category] = (categories[t.category] ?? 0) + 1;
    }
    final dominantCategory = categories.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return MerchantDetail(
      merchantTitle: merchantTitle,
      transactions: txs,
      totalSpent: total,
      transactionCount: txs.length,
      firstSeen: txs.last.date,
      lastSeen: txs.first.date,
      averageAmount: total / txs.length,
      category: dominantCategory,
    );
  }

  @override
  Future<List<MerchantRegistryEntry>> searchMerchantRegistry(
    String query, {
    int limit = 15,
  }) => _searchMerchantRegistryImpl(this, query, limit: limit);

  @override
  Future<List<MerchantRegistryEntry>> fetchTopMerchants({int limit = 10}) =>
      _fetchTopMerchantsImpl(this, limit: limit);

  @override
  Future<MerchantRegistryEntry?> getMerchantRegistryEntry(
    String merchantTitle,
  ) => _getMerchantRegistryEntryImpl(this, merchantTitle);

  @override
  Future<FeeAnalytics> fetchFeeAnalytics() async {
    await _store.ensureInitialized();
    // Fee detection: look for common fee keywords in title or specific fee categories
    final rows = await _store.executor.runSelect(
      "SELECT amount, occurred_at, category, title FROM transactions WHERE "
      "LOWER(title) LIKE '%fee%' OR LOWER(title) LIKE '%charge%' OR LOWER(title) LIKE '%cost%' OR "
      "LOWER(category) LIKE '%fee%' OR LOWER(category) LIKE '%charge%' "
      "ORDER BY occurred_at DESC",
      const [],
    );
    final fees = rows
        .map(
          (r) => (
            amount: _asDouble(r['amount']),
            date: DateTime.fromMillisecondsSinceEpoch(_asInt(r['occurred_at'])),
            category: '${r['category'] ?? ''}',
          ),
        )
        .toList();
    final total = fees.fold<double>(0, (s, f) => s + f.amount);
    final byMonth = <String, MonthlyFee>{};
    for (final f in fees) {
      final key = '${f.date.year}-${f.date.month.toString().padLeft(2, '0')}';
      byMonth.update(
        key,
        (existing) => MonthlyFee(
          year: f.date.year,
          month: f.date.month,
          total: existing.total + f.amount,
          count: existing.count + 1,
        ),
        ifAbsent: () => MonthlyFee(
          year: f.date.year,
          month: f.date.month,
          total: f.amount,
          count: 1,
        ),
      );
    }
    final byCategory = <String, double>{};
    for (final f in fees) {
      byCategory[f.category] = (byCategory[f.category] ?? 0) + f.amount;
    }
    final topCats = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return FeeAnalytics(
      totalFees: total,
      feeCount: fees.length,
      monthlyFees: byMonth.values.toList()
        ..sort((a, b) {
          final cmp = a.year.compareTo(b.year);
          return cmp != 0 ? cmp : a.month.compareTo(b.month);
        }),
      averageFee: fees.isEmpty ? 0 : total / fees.length,
      topFeeCategories: topCats.take(5).map((e) => (e.key, e.value)).toList(),
    );
  }

  String _normalizeMerchantTitle(String title) {
    return title.toLowerCase().trim();
  }

  Future<int> _count(
    String table, {
    required String where,
    required List<Object?> params,
  }) async {
    final rows = await _store.executor.runSelect(
      'SELECT COUNT(*) AS total FROM $table WHERE $where',
      params,
    );
    return _asInt(rows.first['total']);
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

class _QueuedSmsImport {
  const _QueuedSmsImport({
    required this.message,
    this.sourceTimestamp,
    this.sender,
  });

  final String message;
  final DateTime? sourceTimestamp;
  final String? sender;
}
