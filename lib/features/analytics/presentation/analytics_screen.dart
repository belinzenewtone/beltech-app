import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/category_chip.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/widgets/section_header.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_bar_chart.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_category_breakdown.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_overview_cards.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_trend_chart.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(analyticsSnapshotProvider);
    final period = ref.watch(analyticsPeriodProvider);

    return SecondaryPageShell(
      title: 'Analytics',

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodSelector(period: period),
          const SizedBox(height: AppSpacing.sectionGap),
          snapshotState.when(
            data: (snapshot) => _AnalyticsContent(
              snapshot: snapshot,
              period: period,
            ),
            loading: () => _LoadingAnalytics(),
            error: (_, __) => GlassCard(
              tone: GlassCardTone.muted,
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load analytics',
                    style: AppTypography.bodySm(context),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    onPressed: () => ref.invalidate(analyticsSnapshotProvider),
                    label: 'Retry',
                    variant: AppButtonVariant.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({required this.period});

  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: CategoryChip(
            label: 'Weekly',
            selected: period == AnalyticsPeriod.week,
            onTap: () {
              ref.read(analyticsPeriodProvider.notifier).state =
                  AnalyticsPeriod.week;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.listGap),
        Expanded(
          child: CategoryChip(
            label: 'Monthly',
            selected: period == AnalyticsPeriod.month,
            onTap: () {
              ref.read(analyticsPeriodProvider.notifier).state =
                  AnalyticsPeriod.month;
            },
          ),
        ),
      ],
    );
  }
}

class _LoadingAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          tone: GlassCardTone.muted,
          child: Container(
            height: 180,
            alignment: Alignment.center,
            child: const LoadingIndicator(),
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        GlassCard(
          tone: GlassCardTone.muted,
          child: Container(
            height: 180,
            alignment: Alignment.center,
            child: const LoadingIndicator(),
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        GlassCard(
          tone: GlassCardTone.muted,
          child: Container(
            height: 180,
            alignment: Alignment.center,
            child: const LoadingIndicator(),
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        GlassCard(
          tone: GlassCardTone.muted,
          child: Container(
            height: 180,
            alignment: Alignment.center,
            child: const LoadingIndicator(),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsContent extends StatefulWidget {
  const _AnalyticsContent({
    required this.snapshot,
    required this.period,
  });

  final AnalyticsSnapshot snapshot;
  final AnalyticsPeriod period;

  @override
  State<_AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<_AnalyticsContent> {
  /// Which chart mode is active: 0 = Trend (line), 1 = Distribution (bar)
  int _chartMode = 0;

  @override
  Widget build(BuildContext context) {
    final trendPoints = switch (widget.period) {
      AnalyticsPeriod.week => widget.snapshot.weeklySpending,
      AnalyticsPeriod.month => widget.snapshot.monthlySpending,
    };
    final trendTitle = widget.period == AnalyticsPeriod.week
        ? 'Weekly Spending Trend'
        : 'Monthly Spending Trend';
    final distTitle = widget.period == AnalyticsPeriod.week
        ? 'Weekly Distribution'
        : 'Daily Distribution';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Overview', topPadding: 0),
        AnalyticsOverviewCards(snapshot: widget.snapshot),
        const SizedBox(height: AppSpacing.sectionGap),
        // Single chart with Trend / Distribution toggle
        Row(
          children: [
            Expanded(
              child: Text(
                'Spending',
                style: AppTypography.sectionTitle(context),
              ),
            ),
            SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: AppTypography.bodySm(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              segments: const [
                ButtonSegment<int>(value: 0, label: Text('Trend')),
                ButtonSegment<int>(value: 1, label: Text('Distribution')),
              ],
              selected: {_chartMode},
              onSelectionChanged: (s) => setState(() => _chartMode = s.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _chartMode == 0
              ? AnalyticsTrendChart(
                  key: const ValueKey('trend'),
                  title: trendTitle,
                  points: trendPoints,
                )
              : AnalyticsBarChart(
                  key: const ValueKey('dist'),
                  title: distTitle,
                  points: trendPoints,
                ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const SectionHeader('Categories'),
        AnalyticsCategoryBreakdown(
          categories: widget.snapshot.categoryBreakdown,
        ),
      ],
    );
  }
}
