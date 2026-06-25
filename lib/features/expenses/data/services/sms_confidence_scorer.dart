import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';

/// Advanced SMS confidence scoring service.
/// Analyzes parsed MPESA transactions and provides detailed confidence assessment.
class SmsConfidenceScorer {
  /// Score a parsed MPESA transaction and return detailed confidence metrics.
  SmsConfidenceAnalysis scoreTransaction({
    required ParsedMpesaCandidate candidate,
    List<ParsedMpesaCandidate>? recentTransactions,
  }) {
    final scores = <String, double>{};
    var totalWeight = 0.0;
    var weightedScore = 0.0;

    // 1. Code pattern confidence (15% weight) — valid MPESA code format
    final codeScore = candidate.mpesaCode.isNotEmpty ? 1.0 : 0.0;
    scores['code_pattern'] = codeScore;
    weightedScore += codeScore * 0.15;
    totalWeight += 0.15;

    // 2. Amount validity (20% weight) — amount > 0 and reasonable
    final amountScore = _scoreAmount(candidate.amountKes);
    scores['amount_valid'] = amountScore;
    weightedScore += amountScore * 0.20;
    totalWeight += 0.20;

    // 3. Date freshness (15% weight) — transaction not too old/future
    final dateScore = _scoreDateFreshness(candidate.occurredAt);
    scores['date_freshness'] = dateScore;
    weightedScore += dateScore * 0.15;
    totalWeight += 0.15;

    // 4. Merchant/recipient clarity (20% weight) — sender/recipient name identified
    final merchantScore = _scoreMerchantClarity(candidate);
    scores['merchant_clarity'] = merchantScore;
    weightedScore += merchantScore * 0.20;
    totalWeight += 0.20;

    // 5. Transaction type confidence (15% weight) — type clearly identified
    final typeScore = _scoreTransactionType(candidate.transactionType);
    scores['type_confidence'] = typeScore;
    weightedScore += typeScore * 0.15;
    totalWeight += 0.15;

    // 6. Duplicate detection (15% weight) — not a duplicate of recent
    final duplicateScore = _scoreDuplicateLikelihood(
      candidate,
      recentTransactions,
    );
    scores['duplicate_likelihood'] = duplicateScore;
    weightedScore += duplicateScore * 0.15;
    totalWeight += 0.15;

    final finalScore = totalWeight > 0 ? weightedScore / totalWeight : 0.0;

    return SmsConfidenceAnalysis(
      score: finalScore,
      confidence: _scoreToConfidence(finalScore),
      scoreBreakdown: scores,
      reasoning: _generateReasoning(scores, finalScore),
    );
  }

  /// Score amount validity (0.0 to 1.0).
  double _scoreAmount(double amount) {
    if (amount <= 0) return 0.0;
    if (amount < 1) return 0.3;
    if (amount > 10_000_000) return 0.4; // Suspiciously high
    if (amount > 1_000_000) return 0.7;
    return 1.0;
  }

  /// Score date freshness (0.0 to 1.0).
  double _scoreDateFreshness(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    // Future dates are suspicious
    if (diff.inDays < -1) return 0.0;

    // Very recent (within 1 hour) — high confidence
    if (diff.inMinutes <= 60) return 1.0;

    // Same day — good confidence
    if (diff.inDays == 0) return 0.95;

    // Within week — acceptable
    if (diff.inDays <= 7) return 0.85;

    // Within month — declining confidence
    if (diff.inDays <= 30) return 0.6;

    // Older than month — low confidence
    if (diff.inDays <= 90) return 0.3;

    // More than 3 months — very low
    return 0.1;
  }

  /// Score merchant/recipient clarity (0.0 to 1.0).
  double _scoreMerchantClarity(ParsedMpesaCandidate candidate) {
    final hasCounterparty =
        candidate.counterparty != null &&
        candidate.counterparty!.isNotEmpty &&
        candidate.counterparty!.length > 2;

    final hasReason =
        candidate.reason != null &&
        candidate.reason!.isNotEmpty &&
        candidate.reason!.length > 2;

    var score = 0.0;
    if (hasCounterparty) score += 0.6;
    if (hasReason) score += 0.4;

    return score;
  }

  /// Score transaction type confidence (0.0 to 1.0).
  double _scoreTransactionType(MpesaTransactionType type) {
    return switch (type) {
      MpesaTransactionType.sent => 0.95,
      MpesaTransactionType.received => 0.95,
      MpesaTransactionType.paybill => 0.90,
      MpesaTransactionType.buyGoods => 0.90,
      MpesaTransactionType.withdrawal => 0.85,
      MpesaTransactionType.deposit => 0.85,
      MpesaTransactionType.airtime => 0.80,
      MpesaTransactionType.reversal => 0.70,
      MpesaTransactionType.fulizaDraw => 0.75,
      MpesaTransactionType.fulizaRepayment => 0.75,
      MpesaTransactionType.fulizaCharge => 0.80,
      MpesaTransactionType.unknown => 0.4,
    };
  }

  /// Score duplicate likelihood based on recent transactions (0.0 to 1.0).
  /// Higher score = less likely to be a duplicate.
  double _scoreDuplicateLikelihood(
    ParsedMpesaCandidate candidate,
    List<ParsedMpesaCandidate>? recentTransactions,
  ) {
    if (recentTransactions == null || recentTransactions.isEmpty) {
      return 1.0; // No recent data to compare
    }

    // Check for exact or near-exact duplicates in last 24 hours
    final now = DateTime.now();
    final last24h = recentTransactions.where((t) {
      return now.difference(t.occurredAt).inHours <= 24;
    }).toList();

    if (last24h.isEmpty) return 1.0;

    // Look for duplicates with same amount ± 10% within 1 hour
    final amountTolerance = candidate.amountKes * 0.1;
    final exactDuplicates = last24h.where((t) {
      final sameAmount =
          (t.amountKes - candidate.amountKes).abs() <= amountTolerance;
      final withinHour = now.difference(t.occurredAt).inMinutes <= 60;
      return sameAmount && withinHour;
    }).length;

    if (exactDuplicates > 0) return 0.2; // Likely duplicate
    if (exactDuplicates > 1) return 0.0; // Definitely duplicate

    return 1.0; // No duplicates detected
  }

  /// Convert numeric score to confidence enum.
  MpesaConfidence _scoreToConfidence(double score) {
    if (score >= 0.75) return MpesaConfidence.high;
    if (score >= 0.50) return MpesaConfidence.medium;
    return MpesaConfidence.low;
  }

  /// Generate human-readable reasoning for the score.
  String _generateReasoning(Map<String, double> scores, double finalScore) {
    final issues = <String>[];

    if (scores['code_pattern']! < 0.5) {
      issues.add('Invalid or missing MPESA code');
    }
    if (scores['amount_valid']! < 0.5) {
      issues.add('Amount appears invalid or suspicious');
    }
    if (scores['date_freshness']! < 0.5) {
      issues.add('Transaction date is old or invalid');
    }
    if (scores['merchant_clarity']! < 0.3) {
      issues.add('Sender/recipient not clearly identified');
    }
    if (scores['type_confidence']! < 0.5) {
      issues.add('Transaction type unclear');
    }
    if (scores['duplicate_likelihood']! < 0.5) {
      issues.add('Possible duplicate of recent transaction');
    }

    if (issues.isEmpty) {
      return 'All fields validated successfully.';
    }

    return 'Issues found: ${issues.join('; ')}.';
  }
}

/// Detailed confidence analysis result.
class SmsConfidenceAnalysis {
  const SmsConfidenceAnalysis({
    required this.score,
    required this.confidence,
    required this.scoreBreakdown,
    required this.reasoning,
  });

  /// Final confidence score (0.0 to 1.0).
  final double score;

  /// Confidence level (high/medium/low).
  final MpesaConfidence confidence;

  /// Breakdown of individual scoring factors.
  final Map<String, double> scoreBreakdown;

  /// Human-readable explanation of the score.
  final String reasoning;

  @override
  String toString() =>
      'SmsConfidenceAnalysis(score: $score, confidence: $confidence)';
}
