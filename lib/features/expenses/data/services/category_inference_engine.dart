/// Which inference path produced a [CategoryGuess].
/// Consumed by the Phase 6 health dashboard UX to show a confidence label.
enum InferenceSource {
  /// Category determined by the M-Pesa transaction type (e.g. received → Income).
  mpesaKind,

  /// Category determined by a keyword match on the merchant name.
  keyword,

  /// Category determined by an amount-range heuristic when no keyword matched.
  amountHeuristic,
}

class CategoryGuess {
  final String category;
  final double confidence;
  final InferenceSource source;

  const CategoryGuess({
    required this.category,
    required this.confidence,
    required this.source,
  });
}

// ── Merchant name normalization ───────────────────────────────────────────────

/// Strips common noise from a raw merchant name so that
/// "NAIROBI WATER COMPANY LIMITED" and "Nairobi Water" resolve to the same key.
///
/// Steps:
///   1. Uppercase + trim
///   2. Remove trailing company-type tokens (LTD, LIMITED, CO, COMPANY, CORP, INC)
///   3. Remove trailing phone numbers (9-12 digits)
///   4. Remove trailing account / reference tokens (e.g. "/ACC123", "#REF456")
///   5. Collapse whitespace
String normalizeMerchantName(String raw) {
  var name = raw.toUpperCase().trim();
  // Trailing company-type tokens (with optional trailing period / space).
  name = name
      .replaceAll(
        RegExp(
          r'[\s,]+(?:LIMITED|LTD\.?|COMPANY|CO\.?|CORP\.?|INC\.?)[\s,]*$',
        ),
        '',
      )
      .trim();
  // Trailing phone numbers.
  name = name.replaceAll(RegExp(r'\s+\d{9,12}$'), '').trim();
  // Trailing account / reference tokens: /ACC123, #REF, (ACC 12345).
  name = name.replaceAll(RegExp(r'\s*[/#(]\s*\w+\s*\)?$'), '').trim();
  // Collapse multiple spaces.
  name = name.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return name;
}

// ── Category inference engine ─────────────────────────────────────────────────

class CategoryInferenceEngine {
  const CategoryInferenceEngine();

  /// Infers a spending category from [title] (merchant name) and [amountKes].
  ///
  /// Precedence order:
  ///   1. Amount-aware overrides (airtime small amounts, rent large amounts).
  ///   2. Keyword rules in order (first match wins).
  ///   3. Amount-only heuristics when the title is uninformative.
  ///
  /// Returns null when no rule fires.
  CategoryGuess? infer({required String title, required double amountKes}) {
    final lower = title.toLowerCase().trim();

    // 1. Amount-aware overrides.
    final isAirtimeLike =
        lower.contains('airtime') ||
        lower.contains('bundle') ||
        lower.contains('data');
    if (isAirtimeLike && amountKes <= 2000) {
      return const CategoryGuess(
        category: 'Airtime',
        confidence: 0.95,
        source: InferenceSource.amountHeuristic,
      );
    }
    final isRentLike = lower.contains('rent') || lower.contains('landlord');
    if (isRentLike && amountKes >= 5000) {
      return const CategoryGuess(
        category: 'Rent',
        confidence: 0.90,
        source: InferenceSource.amountHeuristic,
      );
    }

    // 2. Keyword rules.
    for (final rule in _keywordRules) {
      for (final keyword in rule.keywords) {
        if (lower.contains(keyword)) {
          return CategoryGuess(
            category: rule.category,
            confidence: rule.confidence,
            source: InferenceSource.keyword,
          );
        }
      }
    }

    // 3. Amount-only heuristics.
    if (amountKes <= 50) {
      return const CategoryGuess(
        category: 'Airtime',
        confidence: 0.50,
        source: InferenceSource.amountHeuristic,
      );
    }
    if (amountKes <= 300) {
      return const CategoryGuess(
        category: 'Food & Dining',
        confidence: 0.40,
        source: InferenceSource.amountHeuristic,
      );
    }
    if (amountKes >= 50000) {
      return const CategoryGuess(
        category: 'Rent',
        confidence: 0.35,
        source: InferenceSource.amountHeuristic,
      );
    }

    return null;
  }
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

// ── Keyword rules (first match wins — order matters) ─────────────────────────
// More specific / higher-confidence rules appear first.
const _keywordRules = [
  // ── Insurance ──────────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Insurance',
    confidence: 0.90,
    keywords: [
      'britam',
      'jubilee insurance',
      'jubilee life',
      'aar insurance',
      'cic insurance',
      'cic group',
      'old mutual',
      'mgen',
      'pioneer insurance',
      'ga life',
      'madison insurance',
      'pacis',
      'resolution insurance',
      'pan africa',
      'heritage insurance',
      'Kenya Re',
    ],
  ),

  // ── Government & regulatory ────────────────────────────────────────────────
  _KeywordRule(
    category: 'Government',
    confidence: 0.90,
    keywords: [
      'kra',
      'kenya revenue',
      'ntsa',
      'national transport',
      'nhif',
      'national hospital',
      'nssf',
      'national social',
      'huduma',
      'ecitizen',
      'e-citizen',
      'county revenue',
      'nairobi county',
      'mombasa county',
      'kisumu county',
      'kilifi county',
      'government of kenya',
      'ministry of',
      'immigration department',
      'passport',
    ],
  ),

  // ── Investments & savings ──────────────────────────────────────────────────
  _KeywordRule(
    category: 'Investments',
    confidence: 0.88,
    keywords: [
      'cma',
      'capital markets',
      'nse',
      'nairobi securities',
      'unit trust',
      'money market fund',
      'treasury bill',
      't-bill',
      'treasury bond',
      'stanlib',
      'sanlam investments',
      'britam asset',
      'equity investments',
      'co-op investments',
      'ndovu',
      'ibuka',
      'genghis capital',
      'faida securities',
      'dyer and blair',
    ],
  ),

  // ── Subscriptions ─────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Subscriptions',
    confidence: 0.88,
    keywords: [
      'netflix',
      'spotify',
      'showmax',
      'dstv',
      'gotv',
      'canal+',
      'canal plus',
      'wwe network',
      'youtube premium',
      'apple music',
      'binge',
      'startimes',
      'amazon prime',
    ],
  ),

  // ── Fuel ──────────────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Fuel',
    confidence: 0.92,
    keywords: [
      'total energies',
      'total petroleum',
      'shell',
      'rubis',
      'kenol',
      'kobil',
      'oilcom',
      'hashi',
      'mogas',
      'petro',
      'gulf energy',
      'caltex',
      'esso',
      'fuel station',
      'petrol station',
      'filling station',
    ],
  ),

  // ── Rent ──────────────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Rent',
    confidence: 0.85,
    keywords: [
      'rent',
      'landlord',
      'caretaker',
      'property management',
      'apartment',
      'bedsitter',
      'studio',
    ],
  ),

  // ── Food & Dining ─────────────────────────────────────────────────────────
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
      'java house',
      'artcaffe',
      'dormans',
      'galito',
      'nandos',
      'mcdonalds',
      'burger',
      'sandwich',
      'nyama choma',
    ],
  ),

  // ── Transport ─────────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Transport',
    confidence: 0.85,
    keywords: [
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
      'national oil',
      'sgr',
      'swvl',
      'little cab',
      'indriver',
      'beba beba',
    ],
  ),

  // ── Airtime & data ────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Airtime',
    confidence: 0.90,
    keywords: [
      'telkom',
      'zuku',
      'internet',
      'wifi',
      'faiba',
      'airtel',
      'safaricom home',
      'faiba4g',
    ],
  ),

  // ── Health ────────────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Health',
    confidence: 0.85,
    keywords: [
      'hospital',
      'pharmacy',
      'clinic',
      'doctor',
      'medical',
      'chemist',
      'dentist',
      'optic',
      'lab',
      'treatment',
      'healthcare',
      'dawa',
      'dispensary',
      'health centre',
      'dialysis',
    ],
  ),

  // ── Bills & Utilities ─────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Bills & Utilities',
    confidence: 0.85,
    keywords: [
      'kplc',
      'electricity',
      'water',
      'nairobi water',
      'power',
      'token',
      'postpaid',
      'kopo kopo',
      'pesapal',
      'safaricom',
      'fiber',
      'garbage',
      'waste',
      'sewerage',
    ],
  ),

  // ── Savings & SACCOs ──────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Savings',
    confidence: 0.78,
    keywords: [
      'sacco',
      'chama',
      'save',
      'savings account',
      'investment club',
      'merry go round',
      'table banking',
    ],
  ),

  // ── Shopping ──────────────────────────────────────────────────────────────
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
      'clothing',
      'fashion',
    ],
  ),

  // ── Loans & Credit ────────────────────────────────────────────────────────
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
      'credit',
      'borrow',
      'repay',
      'overdraft',
      'hustler fund',
      'tala',
      'branch',
      'zenka',
      'timiza',
      'okash',
      'haraka',
      'fadhili',
    ],
  ),

  // ── Entertainment ─────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Entertainment',
    confidence: 0.75,
    keywords: [
      'movie',
      'cinema',
      'imax',
      'game',
      'concert',
      'ticket',
      'club',
      'bar',
      'drink',
      'beer',
      'sports',
      'betting',
      'sportpesa',
      'betin',
      'mozzartbet',
      'bet',
      'lottery',
      'casino',
    ],
  ),

  // ── Education ─────────────────────────────────────────────────────────────
  _KeywordRule(
    category: 'Education',
    confidence: 0.80,
    keywords: [
      'school',
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
      'knec',
      'kenya national examinations',
    ],
  ),

  // ── Transfer (last resort — very broad terms) ─────────────────────────────
  _KeywordRule(
    category: 'Transfer',
    confidence: 0.65,
    keywords: [
      'send to',
      'sent to',
      'transfer',
      'withdraw',
      'atm',
      'agent',
    ],
  ),
];
