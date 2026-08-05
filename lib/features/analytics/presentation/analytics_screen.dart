import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/chart_semantics.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/widgets/section_header.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_fees_card.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_summary_cards.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_top_merchants.dart';
import 'package:beltech/features/analytics/presentation/widgets/category_spend_cards.dart';
import 'package:beltech/features/analytics/presentation/widgets/insights_section.dart';
import 'package:beltech/features/analytics/presentation/widgets/monthly_trend_bars.dart';
import 'package:beltech/features/analytics/presentation/widgets/monthly_breakdown_section.dart';
import 'package:beltech/features/analytics/presentation/widgets/payday_pulse_card.dart';
import 'package:beltech/features/analytics/presentation/widgets/spend_anatomy_card.dart';
import 'package:beltech/features/analytics/presentation/widgets/spending_comparison_card.dart';
import 'package:beltech/features/insights/presentation/providers/insights_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Analytics screen — 2-tab layout matching Kotlin InsightsScreen:
///   • Analytics tab  — period-filtered spend summary + categories + merchants
///   • Insights tab   — 6-month trend chart + deterministic insight cards + anatomy + pulse
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _tabIndex = 0; // 0 = Analytics, 1 = Insights

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(analyticsSnapshotProvider);

    return SecondaryPageShell(
      title: 'Analytics',
      scrollable: false, // we handle scrolling per-tab
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(analyticsSnapshotProvider),
        ),
      ],
      child: Column(
        children: [
          // ── Tab toggle ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _TabToggle(
              selected: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
          ),
          const SizedBox(height: 4),
          // ── Tab content ────────────────────────────────────────────────
          Expanded(
            child: snapshotAsync.when(
              loading: () => const _SkeletonLoader(),
              error: (e, _) => _ErrorView(
                onRetry: () => ref.invalidate(analyticsSnapshotProvider),
              ),
              data: (snapshot) => RefreshIndicator(
                onRefresh: () async {
                  // StreamProvider auto-refreshes; invalidate to force re-fetch.
                  ref.invalidate(analyticsSnapshotProvider);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _tabIndex == 0
                      ? _AnalyticsTab(key: const ValueKey(0), snapshot: snapshot)
                      : _InsightsTab(key: const ValueKey(1), snapshot: snapshot),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline insight banner on Analytics tab header
// ─────────────────────────────────────────────────────────────────────────────

class _InlineInsightBanner extends StatelessWidget {
  const _InlineInsightBanner({required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final change = snapshot.periodChangePercent;
    final spentMore = (change ?? 0) > 0;
    final color = spentMore ? AppColors.danger : AppColors.success;
    final message = change == null
        ? 'View your latest insights'
        : spentMore
            ? 'Spending up ${change.abs().toStringAsFixed(0)}% — tap for Insights'
            : 'Spending down ${change.abs().toStringAsFixed(0)}% — keep it going';

    return GestureDetector(
      onTap: () => context.pushNamed('insights'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              spentMore ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}

String _buildChartLabel(List<MonthlyTotalPoint> history) {
  if (history.isEmpty) return 'No spending data available';
  final nonZero = history.where((p) => p.totalKes > 0).toList();
  if (nonZero.isEmpty) return 'No spending recorded in any month';
  final highest = nonZero.reduce((a, b) => a.totalKes > b.totalKes ? a : b);
  return 'Spending trend, ${nonZero.length} months, highest in ${highest.monthLabel} ${highest.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial Health Gauge in Insights tab header
// ─────────────────────────────────────────────────────────────────────────────

class _HealthGauge extends StatelessWidget {
  const _HealthGauge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : score >= 40
                ? AppColors.orange
                : AppColors.danger;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.favorite_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Health',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Productivity Score · $score%',
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Category All Time insight row
// ─────────────────────────────────────────────────────────────────────────────

class _TopCategoryAllTime extends StatelessWidget {
  const _TopCategoryAllTime({required this.categories});
  final List<AnalyticsCategoryShare> categories;

  @override
  Widget build(BuildContext context) {
    final topCat = categories.isNotEmpty ? categories.first : null;
    if (topCat == null) return const SizedBox.shrink();
    final visual = categoryVisual(topCat.category);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: visual.foreground.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(visual.icon, size: 16, color: visual.foreground),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Category All Time',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${topCat.category} — ${CurrencyFormatter.money(topCat.totalKes)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab toggle
// ─────────────────────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _Tab(label: 'Analytics', active: selected == 0, onTap: () => onChanged(0)),
          _Tab(label: 'Insights', active: selected == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics tab
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerStatefulWidget {
  const _AnalyticsTab({super.key, required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  ConsumerState<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<_AnalyticsTab> {
  @override
  Widget build(BuildContext context) {
    final period = ref.watch(analyticsPeriodProvider);
    final snapshot = widget.snapshot;
    const h = SizedBox(height: 12);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline insight banner — highest-confidence insight
          if (snapshot.periodChangePercent != null) ...[
            _InlineInsightBanner(snapshot: snapshot),
            const SizedBox(height: 12),
          ],
          // Period filter chips
          _PeriodChips(
            selected: period,
            onChanged: (p) =>
                ref.read(analyticsPeriodProvider.notifier).state = p,
          ),
          h,
          // 4-card summary row wrapped in AnimatedSwitcher for period changes
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: AnalyticsSummaryCards(
              key: ValueKey(period),
              snapshot: snapshot,
            ),
          ),
          h,
          // vs Last period comparison
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: SpendingComparisonCard(
              key: ValueKey(period),
              snapshot: snapshot,
            ),
          ),
          h,
          // Category spend cards (with sparklines)
          CategorySpendCards(categories: snapshot.categoryBreakdown),
          h,
          // Fees
          AnalyticsFeesCard(snapshot: snapshot),
          h,
          // Top merchants
          if (snapshot.topMerchants.isNotEmpty) ...[
            SectionHeader('Top Merchants'),
            AnalyticsTopMerchants(merchants: snapshot.topMerchants),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights tab
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsTab extends ConsumerWidget {
  const _InsightsTab({super.key, required this.snapshot});
  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    const h = SizedBox(height: 12);

    // Derived trend label
    final history = snapshot.monthlyHistory;
    String? trendLabel;
    if (history.length >= 6) {
      final firstHalf = history.take(3).map((p) => p.totalKes).toList();
      final secondHalf = history.skip(3).map((p) => p.totalKes).toList();
      final avg1 = firstHalf.reduce((a, b) => a + b) / 3;
      final avg2 = secondHalf.reduce((a, b) => a + b) / 3;
      if (avg1 > 0) {
        final change = ((avg2 - avg1) / avg1) * 100;
        if (change > 5) trendLabel = '↑ Spending is increasing';
        else if (change < -5) trendLabel = '↓ Spending is decreasing';
        else trendLabel = '→ Spending is stable';
      }
    }

    // Highest / lowest month
    final nonZero = history.where((p) => p.totalKes > 0).toList();
    MonthlyTotalPoint? highest, lowest;
    if (nonZero.isNotEmpty) {
      highest = nonZero.reduce((a, b) => a.totalKes > b.totalKes ? a : b);
      lowest = nonZero.reduce((a, b) => a.totalKes < b.totalKes ? a : b);
      if (highest == lowest) lowest = null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 6-month trend bars with screen-reader label
          ChartSemantics(
            label: _buildChartLabel(history),
            child: MonthlyTrendBars(
              monthlyHistory: history,
              onTapMonth: (y, m) =>
                  context.pushNamed('monthly-wrapped', extra: (y, m)),
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 10),
            _HistoryStatCards(history: history),
          ],
          if (trendLabel != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                trendLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ),
          ],
          // Financial Health Gauge in header
          if (snapshot.productivityScore > 0) ...[
            h,
            _HealthGauge(score: snapshot.productivityScore.toInt()),
          ],
          // Highest / lowest month quick links
          if (highest != null || lowest != null) ...[
            h,
            _MonthHighlightRow(
              highest: highest,
              lowest: lowest,
              onTap: (y, m) =>
                  context.pushNamed('monthly-wrapped', extra: (y, m)),
            ),
          ],
          // Top Category All Time insight
          if (snapshot.categoryBreakdown.isNotEmpty) ...[
            h,
            _TopCategoryAllTime(categories: snapshot.categoryBreakdown),
          ],
          h,
          // Monthly history breakdown
          MonthlyBreakdownSection(
            history: history,
            categoryBreakdown: snapshot.categoryBreakdown,
            onTapMonth: (y, m) =>
                context.pushNamed('monthly-wrapped', extra: (y, m)),
          ),
          h,
          // Deterministic insight cards
          insightsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cards) => InsightsSection(insights: cards),
          ),
          h,
          // Spend anatomy
          SpendAnatomyCard(snapshot: snapshot),
          h,
          // Payday pulse
          PaydayPulseCard(snapshot: snapshot),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.selected, required this.onChanged});

  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'This week',
            active: selected == AnalyticsPeriod.week,
            onTap: () => onChanged(AnalyticsPeriod.week),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'This month',
            active: selected == AnalyticsPeriod.month,
            onTap: () => onChanged(AnalyticsPeriod.month),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? scheme.primary
              : scheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: active ? scheme.onPrimary : scheme.onSurface.withOpacity(0.7),
              ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Highest / lowest month links
// ─────────────────────────────────────────────────────────────────────────────

class _MonthHighlightRow extends StatelessWidget {
  const _MonthHighlightRow({
    required this.highest,
    required this.lowest,
    required this.onTap,
  });

  final MonthlyTotalPoint? highest;
  final MonthlyTotalPoint? lowest;
  final void Function(int year, int month) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (highest != null)
          Expanded(
            child: _HighlightTile(
              icon: Icons.arrow_upward_rounded,
              label: 'Highest: ${highest!.monthLabel}',
              amount: highest!.totalKes,
              onTap: () => onTap(highest!.year, highest!.month),
            ),
          ),
        if (highest != null && lowest != null) const SizedBox(width: 10),
        if (lowest != null)
          Expanded(
            child: _HighlightTile(
              icon: Icons.arrow_downward_rounded,
              label: 'Lowest: ${lowest!.monthLabel}',
              amount: lowest!.totalKes,
              onTap: () => onTap(lowest!.year, lowest!.month),
            ),
          ),
      ],
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.icon,
    required this.label,
    required this.amount,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final double amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6))),
                  Text(
                    'KES ${amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / error states
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Period chips
        Row(
          children: [
            AppSkeleton(width: 90, height: 32, borderRadius: 20),
            const SizedBox(width: 8),
            AppSkeleton(width: 100, height: 32, borderRadius: 20),
          ],
        ),
        const SizedBox(height: 14),
        // Summary cards 2x2
        Row(
          children: [
            Expanded(child: AppSkeleton.card(context, height: 72)),
            const SizedBox(width: 10),
            Expanded(child: AppSkeleton.card(context, height: 72)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: AppSkeleton.card(context, height: 72)),
            const SizedBox(width: 10),
            Expanded(child: AppSkeleton.card(context, height: 72)),
          ],
        ),
        const SizedBox(height: 14),
        // Comparison card
        AppSkeleton.card(context, height: 110),
        const SizedBox(height: 14),
        // Category cards
        for (int i = 0; i < 3; i++) ...[
          AppSkeleton.card(context, height: 64),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        AppSkeleton.card(context, height: 58),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Unable to load analytics'),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History stat cards (Avg Monthly / Total Tracked)
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryStatCards extends StatelessWidget {
  const _HistoryStatCards({required this.history});
  final List<MonthlyTotalPoint> history;

  @override
  Widget build(BuildContext context) {
    final nonZero = history.where((p) => p.totalKes > 0).toList();
    if (nonZero.isEmpty) return const SizedBox.shrink();

    final avgMonthly = nonZero
        .map((p) => p.totalKes)
        .reduce((a, b) => a + b) /
        nonZero.length;
    final totalTracked = nonZero.fold(0.0, (sum, p) => sum + p.totalKes);

    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Avg Monthly', value: CurrencyFormatter.money(avgMonthly))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Total Tracked', value: CurrencyFormatter.money(totalTracked))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}