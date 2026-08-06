import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/widgets/section_header.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_fees_card.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_summary_cards.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_top_merchants.dart';
import 'package:beltech/features/analytics/presentation/widgets/category_spend_cards.dart';
import 'package:beltech/features/analytics/presentation/widgets/spending_comparison_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Analytics screen — period-filtered spend summary, categories, and merchants.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(analyticsSnapshotProvider);

    return SecondaryPageShell(
      title: 'Analytics',
      scrollable: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(analyticsSnapshotProvider),
        ),
      ],
      child: snapshotAsync.when(
        loading: () => const _SkeletonLoader(),
        error: (e, _) => _ErrorView(
          onRetry: () => ref.invalidate(analyticsSnapshotProvider),
        ),
        data: (snapshot) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(analyticsSnapshotProvider),
          child: _AnalyticsTab(snapshot: snapshot),
        ),
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
        ? 'Tap to view monthly details'
        : spentMore
            ? 'Spending up ${change.abs().toStringAsFixed(0)}% vs last period'
            : 'Spending down ${change.abs().toStringAsFixed(0)}% — keep it going';

    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        context.pushNamed('monthly-wrapped', extra: (now.year, now.month));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
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
            const SizedBox(width: AppSpacing.sm),
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
  DateTimeRange? _customRange;

  String? get _customRangeLabel {
    if (_customRange == null) return null;
    final s = _customRange!.start;
    final e = _customRange!.end;
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    if (s.year == e.year) {
      return '${s.day} ${months[s.month - 1]}–${e.day} ${months[e.month - 1]}';
    }
    return '${s.day} ${months[s.month - 1]} ${s.year}–${e.day} ${months[e.month - 1]} ${e.year}';
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(analyticsPeriodProvider);
    final snapshot = widget.snapshot;
    const h = SizedBox(height: AppSpacing.md);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline insight banner — highest-confidence insight
          if (snapshot.periodChangePercent != null) ...[
            _InlineInsightBanner(snapshot: snapshot),
            const SizedBox(height: AppSpacing.md),
          ],
          // Period filter chips
          _PeriodChips(
            selected: period,
            customRangeLabel: _customRangeLabel,
            onChanged: (p) {
              ref.read(analyticsPeriodProvider.notifier).state = p;
              if (p != period) setState(() => _customRange = null);
            },
            onCustomTap: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2, 1, 1),
                lastDate: now,
                initialDateRange: _customRange ??
                    DateTimeRange(
                      start: now.subtract(const Duration(days: 30)),
                      end: now,
                    ),
              );
              if (range != null) {
                setState(() => _customRange = range);
                // TODO(phase-4): pass range to a customRangeSnapshotProvider
                // once the repository supports watchSnapshotRange(start, end).
                // For now the chip shows the selection visually.
                ref.invalidate(analyticsSnapshotProvider);
              }
            },
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
// Period filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({
    required this.selected,
    required this.onChanged,
    required this.onCustomTap,
    this.customRangeLabel,
  });

  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;
  final VoidCallback onCustomTap;

  /// When non-null a custom range is active; shows the date span in the chip.
  final String? customRangeLabel;

  @override
  Widget build(BuildContext context) {
    final hasCustom = customRangeLabel != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'This week',
            active: selected == AnalyticsPeriod.week && !hasCustom,
            onTap: () => onChanged(AnalyticsPeriod.week),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: 'This month',
            active: selected == AnalyticsPeriod.month && !hasCustom,
            onTap: () => onChanged(AnalyticsPeriod.month),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
            label: hasCustom ? customRangeLabel! : 'Custom…',
            active: hasCustom,
            onTap: onCustomTap,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm - 2,
        ),
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
// Loading / error states
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.xxl,
      ),
      children: [
        // Period chips
        Row(
          children: [
            AppSkeleton(width: 90, height: 32, borderRadius: 20),
            const SizedBox(width: AppSpacing.sm),
            AppSkeleton(width: 100, height: 32, borderRadius: 20),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.md),
        // Comparison card
        AppSkeleton.card(context, height: 110),
        const SizedBox(height: AppSpacing.md),
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

