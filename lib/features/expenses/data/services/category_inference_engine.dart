class CategoryInferenceEngine {
  const CategoryInferenceEngine();

  CategoryGuess? infer({required String title, required double amountKes}) {
    final lower = title.toLowerCase().trim();

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
    ],
  ),
  _KeywordRule(
    category: 'Transport',
    confidence: 0.85,
    keywords: [
      'fuel',
      'petrol',
      'matatu',
      'bus',
      'uber',
      'bolt',
      'taxi',
      'fare',
      'parking',
      'nduthi',
      'boda',
      'shell',
      'total',
      'rubis',
      'kobil',
    ],
  ),
  _KeywordRule(
    category: 'Airtime',
    confidence: 0.9,
    keywords: [
      'airtime',
      'safaricom',
      'bundle',
      'data',
      'minutes',
      'sms',
      'telkom',
      'zuku',
      'internet',
      'wifi',
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
    ],
  ),
  _KeywordRule(
    category: 'Loans & Credit',
    confidence: 0.85,
    keywords: [
      'loan',
      'm-shwari',
      'kscb',
      'equitel',
      'fuliza',
      'bank',
      'credit',
      'borrow',
      'repay',
      'overdraft',
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
    ],
  ),
  _KeywordRule(
    category: 'Transfer',
    confidence: 0.7,
    keywords: ['send to', 'sent to', 'transfer', 'withdraw', 'atm', 'agent'],
  ),
  _KeywordRule(
    category: 'Savings',
    confidence: 0.65,
    keywords: ['save', 'savings', 'invest', 'fund', 'deposit'],
  ),
];
