part of 'expenses_repository_impl.dart';

Future<String> _resolveLearnedCategoryImpl(
  ExpensesRepositoryImpl repo, {
  required String merchantTitle,
  required String fallbackCategory,
  double? amountKes,
}) async {
  final resolution = await _resolveCategoryWithConfidenceImpl(
    repo,
    merchantTitle: merchantTitle,
    fallbackCategory: fallbackCategory,
    amountKes: amountKes,
  );
  return resolution.category;
}

/// Resolves the best category for a merchant and returns the confidence we have
/// in that choice. Confidence is used by the import pipeline to decide whether
/// a direct-ledger candidate should be reviewed instead.
Future<({String category, double confidence})> _resolveCategoryWithConfidenceImpl(
  ExpensesRepositoryImpl repo, {
  required String merchantTitle,
  required String fallbackCategory,
  double? amountKes,
}) async {
  await repo._store.ensureInitialized();
  final merchantKey = _normalizeMerchantKey(merchantTitle);
  if (merchantKey.isEmpty) {
    return (
      category: fallbackCategory,
      confidence: _fallbackCategoryConfidence,
    );
  }

  // 1. Explicitly learned merchant categories (manual edits or past imports).
  final rows = await repo._store.executor.runSelect(
    'SELECT category FROM merchant_categories WHERE merchant_key = ? LIMIT 1',
    [merchantKey],
  );
  if (rows.isNotEmpty) {
    final category = '${rows.first['category'] ?? ''}'.trim();
    if (category.isNotEmpty) {
      return (category: category, confidence: 1.0);
    }
  }

  // 2. Merchant-learning service override (e.g. cloud model or user profile).
  final learned = await repo._merchantLearningService.resolveCategory(
    merchantTitle: merchantTitle,
    fallbackCategory: fallbackCategory,
  );
  if (learned != fallbackCategory && learned.isNotEmpty) {
    return (category: learned, confidence: 0.95);
  }

  // 3. Combine the type-based fallback with a merchant/amount inference guess.
  CategoryGuess? guess;
  if (amountKes != null) {
    const engine = CategoryInferenceEngine();
    guess = engine.infer(title: merchantTitle, amountKes: amountKes);
  }
  if (guess != null && guess.confidence >= _fallbackCategoryConfidence) {
    return (category: guess.category, confidence: guess.confidence);
  }
  return (
    category: fallbackCategory,
    confidence: _fallbackCategoryConfidence,
  );
}

const double _fallbackCategoryConfidence = 0.5;

Future<void> _learnMerchantCategoryImpl(
  ExpensesRepositoryImpl repo, {
  required String merchantTitle,
  required String category,
}) async {
  await repo._store.ensureInitialized();
  final merchantKey = _normalizeMerchantKey(merchantTitle);
  final cleanedCategory = category.trim();
  if (merchantKey.isEmpty || cleanedCategory.isEmpty) {
    return;
  }
  await repo._store.executor.runInsert(
    'INSERT INTO merchant_categories(merchant_key, category, usage_count, updated_at) '
    'VALUES (?, ?, 1, ?) '
    'ON CONFLICT(merchant_key) DO UPDATE SET '
    'category = excluded.category, '
    'usage_count = merchant_categories.usage_count + 1, '
    'updated_at = excluded.updated_at',
    [merchantKey, cleanedCategory, DateTime.now().millisecondsSinceEpoch],
  );
  await repo._merchantLearningService.learn(
    merchantTitle: merchantTitle,
    category: cleanedCategory,
  );
}

String _normalizeMerchantKey(String merchantTitle) {
  return merchantTitle
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Future<List<MerchantRegistryEntry>> _searchMerchantRegistryImpl(
  ExpensesRepositoryImpl repo,
  String query, {
  int limit = 15,
}) async {
  await repo._store.ensureInitialized();
  final pattern = '%${_normalizeMerchantKey(query)}%';
  final rows = await repo._store.executor.runSelect(
    'SELECT merchant_key, category, usage_count, updated_at '
    'FROM merchant_categories '
    'WHERE merchant_key LIKE ? '
    'ORDER BY usage_count DESC, updated_at DESC '
    'LIMIT ?',
    [pattern, limit],
  );
  return rows.map(_rowToMerchantRegistryEntry).toList();
}

Future<List<MerchantRegistryEntry>> _fetchTopMerchantsImpl(
  ExpensesRepositoryImpl repo, {
  int limit = 10,
}) async {
  await repo._store.ensureInitialized();
  final rows = await repo._store.executor.runSelect(
    'SELECT merchant_key, category, usage_count, updated_at '
    'FROM merchant_categories '
    'ORDER BY usage_count DESC, updated_at DESC '
    'LIMIT ?',
    [limit],
  );
  return rows.map(_rowToMerchantRegistryEntry).toList();
}

Future<MerchantRegistryEntry?> _getMerchantRegistryEntryImpl(
  ExpensesRepositoryImpl repo,
  String merchantTitle,
) async {
  await repo._store.ensureInitialized();
  final key = _normalizeMerchantKey(merchantTitle);
  if (key.isEmpty) return null;
  final rows = await repo._store.executor.runSelect(
    'SELECT merchant_key, category, usage_count, updated_at '
    'FROM merchant_categories '
    'WHERE merchant_key = ? '
    'LIMIT 1',
    [key],
  );
  if (rows.isEmpty) return null;
  return _rowToMerchantRegistryEntry(rows.first);
}

MerchantRegistryEntry _rowToMerchantRegistryEntry(Map<String, Object?> row) {
  return MerchantRegistryEntry(
    merchantKey: '${row['merchant_key'] ?? ''}',
    category: '${row['category'] ?? ''}',
    usageCount: (row['usage_count'] as num?)?.toInt() ?? 0,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      (row['updated_at'] as num?)?.toInt() ?? 0,
    ),
  );
}
