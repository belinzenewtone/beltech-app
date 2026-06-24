part of 'expenses_repository_impl.dart';

Future<String> _resolveLearnedCategoryImpl(
  ExpensesRepositoryImpl repo, {
  required String merchantTitle,
  required String fallbackCategory,
  double? amountKes,
}) async {
  await repo._store.ensureInitialized();
  final merchantKey = _normalizeMerchantKey(merchantTitle);
  if (merchantKey.isEmpty) {
    return fallbackCategory;
  }
  final rows = await repo._store.executor.runSelect(
    'SELECT category FROM merchant_categories WHERE merchant_key = ? LIMIT 1',
    [merchantKey],
  );
  if (rows.isNotEmpty) {
    final category = '${rows.first['category'] ?? ''}'.trim();
    if (category.isNotEmpty) {
      return category;
    }
  }
  final learned = await repo._merchantLearningService.resolveCategory(
    merchantTitle: merchantTitle,
    fallbackCategory: fallbackCategory,
  );
  if (learned == fallbackCategory && amountKes != null) {
    const engine = CategoryInferenceEngine();
    final guess = engine.infer(title: merchantTitle, amountKes: amountKes);
    if (guess != null && guess.confidence >= 0.6) {
      return guess.category;
    }
  }
  return learned;
}

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
