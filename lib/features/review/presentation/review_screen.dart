import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:beltech/features/review/domain/financial_health_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Weekly ritual screen — health score ring, 7-day spend bars,
/// what-changed card, wins/risks/ritual cards.
/// Data is driven by the current week's AnalyticsSnapshot.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(analyticsSnapshotProvider);

    return SecondaryPageShell(
      title: 'Weekly Review',
      child: snapshotAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSkeleton.card(context, height: 160),
            const SizedBox(height: 16),
            AppSkeleton.card(context, height: 120),
            const SizedBox(height: 16),
            AppSkeleton.card(context, height: 100),
          ],
        ),
        error: (e, _) => Center(
          child: Text('Unable to load review data',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        data: (snapshot) => _ReviewBody(snapshot: snapshot),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    // Compute health score from live data.
    final uncategorized = snapshot.categoryBreakdown
        .where((c) => c.category.toLowerCase() == 'other' ||
            c.category.toLowerCase() == 'uncategorized')
        .fold<int>(0, (sum, c) => sum + c.weeklySparkline.fold<int>(0,
            (s, _) => s + 1));

    final score = FinancialHealthScore.compute(
      currentWeekSpendKes: snapshot.totalSpentThisPeriodKes,
      previousWeekSpendKes: snapshot.previousPeriodTotalKes,
      uncategorizedCount: uncategorized,
      fulizaUsageCount: 0, // Fuliza count not in snapshot; defaults to neutral
      tasksCompleted: snapshot.totalTasksCompleted,
      tasksTotal: snapshot.totalTasksCompleted + snapshot.totalTasksPending,
    );

    // 7-day daily spend from weeklySpending points.
    final dailySpends = snapshot.weeklySpending
        .map((p) => p.amountKes)
        .toList();
    // Pad or trim to exactly 7 entries.
    final spends = List.generate(7, (i) =>
        i < dailySpends.length ? dailySpends[i] : 0.0);
    final avgSpend = spends.where((v) => v > 0).isEmpty
        ? 0.0
        : spends.where((v) => v > 0).reduce((a, b) => a + b) /
            spends.where((v) => v > 0).length;

    // What Changed: use snapshot-derived values.
    final pctChange = snapshot.periodChangePercent;
    final topCat = snapshot.categoryBreakdown.isNotEmpty
        ? snapshot.categoryBreakdown.first
        : null;
    final taskTotal = snapshot.totalTasksCompleted + snapshot.totalTasksPending;
    final taskLabel = taskTotal > 0
        ? '${snapshot.totalTasksCompleted} of $taskTotal'
        : 'No tasks';

    // Wins / Risks from snapshot
    final wins = <String>[
      if (snapshot.totalTasksCompleted > 0 &&
          snapshot.totalTasksPending == 0)
        'All tasks completed this week',
      if ((snapshot.periodChangePercent ?? 1) <= 0)
        'Spending stayed flat or decreased vs last period',
      if (snapshot.feesPaidKes == 0) 'Zero fees paid this period',
    ];
    final risks = <String>[
      if (snapshot.totalTasksPending > 0)
        '${snapshot.totalTasksPending} tasks still pending',
      if ((snapshot.periodChangePercent ?? 0) > 20)
        'Spending up ${pctChange?.toStringAsFixed(0) ?? '?'}% vs last period',
    ];
    if (wins.isEmpty) wins.add('Keep tracking your spending consistently');
    if (risks.isEmpty) risks.add('Looking good — no immediate risks detected');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Health Score Ring ──────────────────────────────────────
          _HealthScoreRing(score: score),
          const SizedBox(height: 16),
          // ── 7-Day Spend Bars ───────────────────────────────────────
          _DailySpendBars(spends: spends, avg: avgSpend),
          const SizedBox(height: 16),
          // ── What Changed card ─────────────────────────────────────
          _WhatChangedCard(
            pctChange: pctChange,
            taskLabel: taskLabel,
            topCategory: topCat != null
                ? '${topCat.category} · KSh ${topCat.totalKes.toStringAsFixed(0)}'
                : '—',
          ),
          const SizedBox(height: 16),
          // ── Wins / Risks ───────────────────────────────────────────
          _WinsRisksSection(wins: wins, risks: risks),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health Score Ring
// ─────────────────────────────────────────────────────────────────────────────

class _HealthScoreRing extends StatefulWidget {
  const _HealthScoreRing({required this.score});
  final int score;

  @override
  State<_HealthScoreRing> createState() => _HealthScoreRingState();
}

class _HealthScoreRingState extends State<_HealthScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = FinancialHealthScore.tierLabel(widget.score);
    final color = widget.score >= 80
        ? AppColors.success
        : widget.score >= 60
            ? AppColors.warning
            : widget.score >= 40
                ? AppColors.orange
                : AppColors.danger;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final animScore = (widget.score * _anim.value).round();
        return Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 6),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$animScore',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-Day Spend Bars — staggered entry animation + tap tooltip
// ─────────────────────────────────────────────────────────────────────────────

class _DailySpendBars extends StatefulWidget {
  const _DailySpendBars({required this.spends, required this.avg});
  final List<double> spends;
  final double avg;

  @override
  State<_DailySpendBars> createState() => _DailySpendBarsState();
}

class _DailySpendBarsState extends State<_DailySpendBars>
    with SingleTickerProviderStateMixin {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late final AnimationController _controller;
  int? _selectedBar;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 350 + widget.spends.length * 50),
      vsync: this,
    );
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spends = widget.spends;
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
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = spends[i];
                final frac = maxKes > 0 ? (v / maxKes).clamp(0.0, 1.0) : 0.0;
                final isFuture = i > today;
                final bgColor = isFuture
                    ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)
                    : v > widget.avg * 1.5
                        ? AppColors.danger
                        : v <= widget.avg
                            ? AppColors.success
                            : AppColors.warning;

                final staggerStart = (i * 0.05).clamp(0.0, 1.0);
                final barAnim = Tween<double>(begin: 0, end: frac * 70).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      staggerStart,
                      (staggerStart + 0.35).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                );

                final isSelected = _selectedBar == i;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _selectedBar = isSelected ? null : i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (_, __) => Container(
                                  height: barAnim.value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [bgColor, bgColor.withOpacity(0.55)],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                              ),
                              if (isSelected && v > 0)
                                Positioned(
                                  top: -22,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.tooltipBackground,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'KSh ${v.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
  const _WhatChangedCard({
    required this.pctChange,
    required this.taskLabel,
    required this.topCategory,
  });

  final double? pctChange;
  final String taskLabel;
  final String topCategory;

  @override
  Widget build(BuildContext context) {
    final spendingLabel = pctChange == null
        ? 'No prior period data'
        : pctChange! > 0
            ? '↑ ${pctChange!.abs().toStringAsFixed(1)}% vs last period'
            : '↓ ${pctChange!.abs().toStringAsFixed(1)}% vs last period';
    final spendColor = (pctChange ?? 0) > 0 ? AppColors.danger : AppColors.success;

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
          _StatRow(label: 'Spending', value: spendingLabel, color: spendColor),
          const Divider(height: 20),
          _StatRow(label: 'Tasks completed', value: taskLabel, color: AppColors.warning),
          const Divider(height: 20),
          _StatRow(label: 'Top category', value: topCategory, color: AppColors.accent),
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
  const _WinsRisksSection({required this.wins, required this.risks});
  final List<String> wins;
  final List<String> risks;

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
          _BulletList(color: AppColors.success, title: 'Wins', items: wins),
          const SizedBox(height: 14),
          _BulletList(color: AppColors.danger, title: 'Risks', items: risks),
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
            'Take 5 minutes to review any uncategorised transactions and check off pending tasks.',
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
