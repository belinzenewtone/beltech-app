import 'dart:math';

import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';

/// Calculates a financial health score (0-100) based on the data context.
/// Inspired by Kotlin app's FinancialHealthCalculator.
class FinancialHealthCalculator {
  const FinancialHealthCalculator();

  int calculate(DataContext ctx) {
    int score = 50;

    // Savings rate: income vs spending
    if (ctx.monthIncome > 0) {
      final savingsRate =
          (ctx.monthIncome - ctx.monthSpending) / ctx.monthIncome;
      if (savingsRate >= 0.2) {
        score += 15;
      } else if (savingsRate >= 0.1) {
        score += 8;
      } else if (savingsRate >= 0) {
        score += 2;
      } else {
        score -= 10;
      }
    }

    // Task discipline
    if (ctx.overdueTasksCount == 0) {
      score += 5;
    } else {
      score -= min(ctx.overdueTasksCount * 3, 15);
    }

    // Learning habit
    if (ctx.learningStreak >= 7) {
      score += 5;
    } else if (ctx.learningStreak >= 3) {
      score += 3;
    }

    // Goals progress
    if (ctx.goals.isNotEmpty) {
      final avgProgress =
          ctx.goals.map((g) => g.progressPercent).reduce((a, b) => a + b) /
          ctx.goals.length;
      if (avgProgress >= 0.5) {
        score += 5;
      } else if (avgProgress >= 0.25) {
        score += 3;
      }
    }

    // Loan burden
    if (ctx.loansOutstanding > 0) {
      if (ctx.monthIncome > 0 && ctx.loansOutstanding / ctx.monthIncome > 3) {
        score -= 10;
      } else if (ctx.monthIncome > 0 &&
          ctx.loansOutstanding / ctx.monthIncome > 1.5) {
        score -= 5;
      }
    }

    // Bills health
    if (ctx.billsOverdue.isNotEmpty) {
      score -= min(ctx.billsOverdue.length * 5, 15);
    } else if (ctx.billsUpcoming.isNotEmpty) {
      score += 3;
    }

    // Anomalies penalty
    final highSeverity = ctx.anomalies
        .where((a) => a.severity == AnomalySeverity.high)
        .length;
    score -= min(highSeverity * 5, 15);

    return score.clamp(0, 100);
  }

  String healthLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }
}
