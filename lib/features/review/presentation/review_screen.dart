import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/review/domain/financial_health_score.dart';
import 'package:flutter/material.dart';

/// Weekly ritual screen — health score ring, 7-day spend bars,
/// what-changed card, wins/risks/ritual cards.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // Placeholder data — wired to real repository in the provider step.
  final _score = 78;
  final _dailySpends = <double>[120, 340, 0, 210, 450, 180, 0];
  final _avgSpend = 215.0;

  @override
  Widget build(BuildContext context) {
    return SecondaryPageShell(
      title: 'Weekly Review',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Health Score Ring ──────────────────────────────────────
            _HealthScoreRing(score: _score),
            const SizedBox(height: 16),
            // ── 7-Day Spend Bars ───────────────────────────────────────
            _DailySpendBars(spends: _dailySpends, avg: _avgSpend),
            const SizedBox(height: 16),
            // ── What Changed card ─────────────────────────────────────
            _WhatChangedCard(),
            const SizedBox(height: 16),
            // ── Wins / Risks ───────────────────────────────────────────
            _WinsRisksSection(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health Score Ring
// ─────────────────────────────────────────────────────────────────────────────

class _HealthScoreRing extends StatelessWidget {
  const _HealthScoreRing({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final label = FinancialHealthScore.tierLabel(score);
    final color = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : score >= 40
                ? AppColors.orange
                : AppColors.danger;

    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 6,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 36,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-Day Spend Bars
// ─────────────────────────────────────────────────────────────────────────────

class _DailySpendBars extends StatelessWidget {
  const _DailySpendBars({required this.spends, required this.avg});
  final List<double> spends;
  final double avg;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxKes = spends.fold<double>(0, (a, b) => a > b ? a : b);
    final today = DateTime.now().weekday - 1;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = spends[i];
                final frac = maxKes > 0 ? (v / maxKes).clamp(0.0, 1.0) : 0.0;
                final isFuture = i > today;
                final bgColor = isFuture
                    ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)
                    : v > avg * 1.5
                        ? AppColors.danger
                        : v <= avg
                            ? AppColors.success
                            : AppColors.warning;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: frac * 70,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _days[i],
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// What Changed card
// ─────────────────────────────────────────────────────────────────────────────

class _WhatChangedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Changed',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _StatRow(label: 'Spending', value: '↑ 12% vs last week', color: AppColors.danger),
          const Divider(height: 20),
          _StatRow(label: 'Tasks completed', value: '7 of 10', color: AppColors.warning),
          const Divider(height: 20),
          _StatRow(label: 'Top category', value: 'Food · KSh 1,200', color: AppColors.accent),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wins / Risks / Ritual
// ─────────────────────────────────────────────────────────────────────────────

class _WinsRisksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wins & Risks',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const _BulletList(
            color: AppColors.success,
            title: 'Wins',
            items: [
              'No Fuliza usage this week',
              'Spending under 3 days stayed below average',
            ],
          ),
          const SizedBox(height: 14),
          const _BulletList(
            color: AppColors.danger,
            title: 'Risks',
            items: [
              '2 uncategorized transactions',
              'Task completion at 70% — trending down',
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Review Ritual',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Take 5 minutes to categorise the 2 pending transactions and check off your overdue tasks.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.color,
    required this.title,
    required this.items,
  });

  final Color color;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13)),
                  Expanded(
                    child: Text(item,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            )),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
