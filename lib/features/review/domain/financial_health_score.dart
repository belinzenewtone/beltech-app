/// Financial Health Score algorithm matching Kotlin's health computation.
///
/// Base: 50 points. Score is clamped to [0, 100].
class FinancialHealthScore {
  FinancialHealthScore._();

  /// Computes health score from weekly metrics.
  ///
  /// Returns a score 0–100 based on:
  /// - Spending trend vs previous week
  /// - Uncategorized transaction count
  /// - Fuliza usage
  /// - Task completion rate
  static int compute({
    required double currentWeekSpendKes,
    required double previousWeekSpendKes,
    required int uncategorizedCount,
    required int fulizaUsageCount,
    required int tasksCompleted,
    required int tasksTotal,
  }) {
    int score = 50;

    // ── Spending trend ──────────────────────────────────────────────────
    if (previousWeekSpendKes > 0) {
      final change = (currentWeekSpendKes - previousWeekSpendKes) / previousWeekSpendKes;
      if (currentWeekSpendKes <= previousWeekSpendKes) {
        score += 20; // spent less or equal
      } else if (change <= 0.2) {
        score += 10; // within 20% increase
      } else if (change > 0.5) {
        score -= 20; // >50% increase
      }
    }

    // ── Uncategorized transactions ──────────────────────────────────────
    if (uncategorizedCount == 0) {
      score += 20;
    } else if (uncategorizedCount <= 3) {
      score += 10;
    } else if (uncategorizedCount > 8) {
      score -= 10;
    }

    // ── Fuliza usage ────────────────────────────────────────────────────
    if (fulizaUsageCount == 0) {
      score += 10;
    } else if (fulizaUsageCount > 2) {
      score -= 10;
    }

    // ── Task completion ─────────────────────────────────────────────────
    if (tasksTotal > 0) {
      final rate = tasksCompleted / tasksTotal;
      if (rate >= 0.8) {
        score += 10;
      } else if (rate >= 0.5) {
        score += 5;
      }
    }

    return score.clamp(0, 100);
  }

  /// Returns a human-readable tier label for the given score.
  static String tierLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs attention';
  }
}
