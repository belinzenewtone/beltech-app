class CategoryInferenceEngine {
  const CategoryInferenceEngine();

  /// Infers a category from merchant title and amount.
  ///
  /// Keyword matches take priority. If no keyword matches, amount heuristics
  /// provide a weak signal. The returned confidence is always <= 1.0.
  CategoryGuess? infer({required String title, required double amountKes}) {
    final lower = title.toLowerCase().trim();

    // 1. Amount-aware overrides for common Kenyan spending patterns.
    final isAirtimeKeyword =
        lower.contains('airtime') ||
        lower.contains('bundle') ||
        lower.contains('data');
    final isFuelKeyword =
        lower.contains('fuel') ||
        lower.contains('petrol') ||
        lower.contains('diesel') ||
        lower.contains('gas') ||
        lower.contains('shell') ||
        lower.contains('total') ||
        lower.contains('rubis') ||
        lower.contains('kobil') ||
        lower.contains('esso') ||
        lower.contains('gulf') ||
        lower.contains('caltex');
    final isRentKeyword = lower.contains('rent') || lower.contains('house');

    if (isAirtimeKeyword && amountKes <= 2000) {
      return const CategoryGuess(category: 'Airtime', confidence: 0.95);
    }
    if (isFuelKeyword) {
      return const CategoryGuess(category: 'Transport', confidence: 0.95);
    }
    if (isRentKeyword && amountKes >= 10000) {
      return const CategoryGuess(category: 'Rent', confidence: 0.9);
    }

    // 2. Keyword-based classification.
    for (final rule in _keywordRules) {
      for (final keyword in rule.keywords) {
        if (lower.contains(keyword)) {
          return CategoryGuess(
            category: rule.category,
            confidence: rule.confidence,
          );
        }
      }
    }

    // 3. Amount-only heuristics for cases where the title is uninformative.
    if (amountKes <= 50) {
      return const CategoryGuess(category: 'Airtime', confidence: 0.5);
    }
    if (amountKes <= 300) {
      return const CategoryGuess(category: 'Food & Dining', confidence: 0.4);
    }
    if (amountKes >= 50000) {
      return const CategoryGuess(category: 'Rent', confidence: 0.35);
    }

    return null;
  }
}

class CategoryGuess {
  final String category;
  final double confidence;
  const CategoryGuess({required this.category, required this.confidence});
}

class _KeywordRule {
  final String category;
  final double confidence;
  final List<String> keywords;
  const _KeywordRule({
    required this.category,
    required this.confidence,
    required this.keywords,
  });
}

const _keywordRules = [
  _KeywordRule(
    category: 'Food & Dining',
    confidence: 0.85,
    keywords: [
      'naivas',
      'quickmart',
      'carrefour',
      'chandarana',
      'restaurant',
      'hotel',
      'cafe',
      'kfc',
      'chicken',
      'pizza',
      'meal',
      'lunch',
      'dinner',
      'breakfast',
      'food',
      'supermarket',
      'grocery',
      'butchery',
      'bakery',
      'mutura',
      'snack',
      'glovo',
      'bolt food',
      'uber eats',
      'jumia food',
      'mama mboga',
    ],
  ),
  _KeywordRule(
    category: 'Transport',
    confidence: 0.85,
    keywords: [
      'fuel',
      'petrol',
      'diesel',
      'matatu',
      'bus',
      'train',
      'uber',
      'bolt',
      'taxi',
      'fare',
      'parking',
      'nduthi',
      'boda',
      'bodaboda',
      'shell',
      'total',
      'rubis',
      'kobil',
      'esso',
      'gulf',
      'caltex',
      'national oil',
    ],
  ),
  _KeywordRule(
    category: 'Airtime',
    confidence: 0.9,
    keywords: [
      // Amount-aware overrides handle 'airtime', 'bundle' and 'data' so that
      // large amounts are not misclassified as airtime.
      'telkom',
      'zuku',
      'internet',
      'wifi',
      'faiba',
      'airtel',
    ],
  ),
  _KeywordRule(
    category: 'Bills & Utilities',
    confidence: 0.85,
    keywords: [
      'kplc',
      'electricity',
      'water',
      'nairobi water',
      'dstv',
      'gotv',
      'netflix',
      'rent',
      'house',
      'power',
      'token',
      'postpaid',
      'till',
      'paybill',
      'kopo kopo',
      'pesapal',
      'safaricom',
      'fiber',
      'garbage',
    ],
  ),
  _KeywordRule(
    category: 'Shopping',
    confidence: 0.75,
    keywords: [
      'shop',
      'mart',
      'store',
      'mall',
      'clothes',
      'shoe',
      'dress',
      'electronics',
      'hardware',
      'amazon',
      'jiji',
      'jumia',
      'shein',
      'aliexpress',
      'killimall',
      'pigia',
    ],
  ),
  _KeywordRule(
    category: 'Health',
    confidence: 0.85,
    keywords: [
      'hospital',
      'pharmacy',
      'clinic',
      'doctor',
      'nhif',
      'medical',
      'chemist',
      'dentist',
      'optic',
      'lab',
      'treatment',
      'healthcare',
      'dawa',
    ],
  ),
  _KeywordRule(
    category: 'Loans & Credit',
    confidence: 0.85,
    keywords: [
      'loan',
      'm-shwari',
      'mshwari',
      'kcb m-pesa',
      'equitel',
      'fuliza',
      'bank',
      'credit',
      'borrow',
      'repay',
      'overdraft',
      'hustler fund',
      'sacco',
      'chama',
    ],
  ),
  _KeywordRule(
    category: 'Entertainment',
    confidence: 0.75,
    keywords: [
      'movie',
      'cinema',
      'game',
      'concert',
      'ticket',
      'club',
      'bar',
      'drink',
      'beer',
      'sports',
      'betting',
      'lottery',
      'casino',
    ],
  ),
  _KeywordRule(
    category: 'Education',
    confidence: 0.8,
    keywords: [
      'school',
      'fee',
      'tuition',
      'book',
      'university',
      'college',
      'course',
      'exam',
      'library',
      'study',
      'textbook',
      'stationery',
    ],
  ),
  _KeywordRule(
    category: 'Transfer',
    confidence: 0.7,
    keywords: [
      'send to',
      'sent to',
      'transfer',
      'withdraw',
      'atm',
      'agent',
      'mpesa send',
    ],
  ),
  _KeywordRule(
    category: 'Savings',
    confidence: 0.65,
    keywords: [
      'save',
      'savings',
      'invest',
      'fund',
      'deposit',
      'money market',
      'treasury bill',
    ],
  ),
];
