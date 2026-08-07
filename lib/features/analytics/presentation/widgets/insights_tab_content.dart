import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/section_header.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/domain/entities/monthly_breakdown_data.dart';
import 'package:beltech/features/analytics/presentation/widgets/monthly_trend_bars.dart';
import 'package:beltech/features/analytics/presentation/widgets/payday_pulse_card.dart';
import 'package:beltech/features/analytics/presentation/widgets/spend_anatomy_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Insights tab — mirrors Kotlin `InsightsContent` in InsightsScreen.kt:
/// monthly trend, average/total, spending insights, history, payday pulse,
/// and spend anatomy.
class InsightsTabContent extends StatelessWidget {
  const InsightsTabContent({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot.monthlyHistory.isNotEmpty) ...[
          MonthlyTrendBars(
            monthlyHistory: snapshot.monthlyHistory,
            onTapMonth: (year, month) => context.pushNamed(
              'monthly-wrapped',
              extra: (year, month),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Monthly',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.money(snapshot.avgMonthlyExpenseKes),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Tracked',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.money(snapshot.totalTrackedKes),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _SpendingInsightsCard(snapshot: snapshot),
        const SizedBox(height: AppSpacing.md),
        if (snapshot.monthBreakdown.isNotEmpty) ...[
          _HistorySection(months: snapshot.monthBreakdown),
          const SizedBox(height: AppSpacing.sm),
        ],
        PaydayPulseCard(snapshot: snapshot),
        const SizedBox(height: AppSpacing.sm),
        SpendAnatomyCard(snapshot: snapshot),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History — shows 3 months by default, expandable via "Show more"
// ─────────────────────────────────────────────────────────────────────────────

class _HistorySection extends StatefulWidget {
  const _HistorySection({required this.months});

  final List<MonthlyBreakdownData> months;

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visible = _expanded ? widget.months : widget.months.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('History'),
        ...visible.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HistoryCard(month: m),
            )),
        if (widget.months.length > 3)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  key: ValueKey(_expanded),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spending Insights card — Highest/Lowest Month, Top Category, Trend rows
// ─────────────────────────────────────────────────────────────────────────────

class _SpendingInsightsCard extends StatelessWidget {
  const _SpendingInsightsCard({required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final history = snapshot.monthlyHistory;
    final expenseMonths = history.where((m) => m.totalKes > 0).toList();
    MonthlyTotalPoint? highest;
    MonthlyTotalPoint? lowest;
    if (expenseMonths.isNotEmpty) {
      highest = expenseMonths.reduce((a, b) =>
          a.totalKes >= b.totalKes ? a : b);
      if (expenseMonths.length > 1) {
        lowest = expenseMonths.reduce((a, b) =>
            a.totalKes <= b.totalKes ? a : b);
      }
    }

    final bad = Theme.of(context).colorScheme.error;
    final good = AppColors.success;
    final muted = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.6);
    final topCat = snapshot.topCategoryAllTime;
    final topColor = topCat != null
        ? categoryVisual(topCat).foreground
        : muted;
    final trendColor = switch (snapshot.trend) {
      'increasing' => bad,
      'decreasing' => good,
      _ => muted,
    };
    final MonthlyTotalPoint? highestValue = highest;
    final MonthlyTotalPoint? lowestValue = lowest;
    final Widget? highestRow = highestValue == null
        ? null
        : _InsightRow(
            label: 'Highest Month',
            detail: '${highestValue.fullLabel} · ${CurrencyFormatter.money(highestValue.totalKes)}',
            color: bad,
            onTap: () => context.pushNamed(
              'monthly-wrapped',
              extra: (highestValue.year, highestValue.month),
            ),
          );
    final Widget? lowestRow = lowestValue == null
        ? null
        : _InsightRow(
            label: 'Lowest Month',
            detail: '${lowestValue.fullLabel} · ${CurrencyFormatter.money(lowestValue.totalKes)}',
            color: good,
            onTap: () => context.pushNamed(
              'monthly-wrapped',
              extra: (lowestValue.year, lowestValue.month),
            ),
          );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Spending Insights',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ?highestRow,
          ?lowestRow,
          if (topCat != null && snapshot.topCategoryAllTimePct != null)
            _InsightRow(
              label: 'Top Category',
              detail: '${topCat[0].toUpperCase()}${topCat.substring(1)} · '
                  '${snapshot.topCategoryAllTimePct!.toStringAsFixed(1)}%',
              color: topColor,
            ),
          _InsightRow(
            label: 'Trend',
            detail: snapshot.trend[0].toUpperCase() +
                snapshot.trend.substring(1),
            color: trendColor,
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.detail,
    required this.color,
    this.onTap,
  });

  final String label;
  final String detail;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Theme.of(context).colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History — expandable per-month cards with delta pill + top categories
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({required this.month});

  final MonthlyBreakdownData month;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.month;
    final delta = m.monthOverMonthPct;
    final dCol = delta == null || delta == 0
        ? Theme.of(context).colorScheme.outlineVariant
        : delta > 0
            ? Theme.of(context).colorScheme.error
            : AppColors.success;
    final rowIcon = delta == null || delta == 0
        ? Icons.remove_rounded
        : delta > 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;

    return AppCard(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dCol.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(rowIcon, size: 16, color: dCol),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              m.monthLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            if (delta != null && delta != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: dCol.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: dCol,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '${m.txCount} transactions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.money(m.totalKes),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && m.topCategories.isNotEmpty) ...[
            Divider(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.3),
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Categories',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...m.topCategories.map((cat) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CategoryBar(cat: cat),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.cat});

  final MonthlyBreakdownCategory cat;

  @override
  Widget build(BuildContext context) {
    final color = categoryVisual(cat.category).foreground;
    final fraction = (cat.pct / 100).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            cat.category[0].toUpperCase() + cat.category.substring(1),
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            CurrencyFormatter.money(cat.totalKes),
            textAlign: TextAlign.right,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
