part of 'week_review_screen.dart';

class _TrendGrid extends StatelessWidget {
  const _TrendGrid({required this.review});

  final WeekReviewData review;

  @override
  Widget build(BuildContext context) {
    final completionDelta =
        review.completionRateThisWeek - review.completionRateLastWeek;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TrendCard(
                label: 'Spend',
                value: CurrencyFormatter.money(review.weeklySpendKes),
                delta: _deltaMoney(review.spendDeltaKes),
                deltaColor: review.spendDeltaKes <= 0
                    ? AppColors.success
                    : AppColors.danger,
                icon: Icons.trending_down,
              ),
            ),
            const SizedBox(width: AppSpacing.listGap),
            Expanded(
              child: _TrendCard(
                label: 'Income',
                value: CurrencyFormatter.money(review.weeklyIncomeKes),
                delta: _deltaMoney(review.incomeDeltaKes),
                deltaColor: review.incomeDeltaKes >= 0
                    ? AppColors.success
                    : AppColors.warning,
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.listGap),
        Row(
          children: [
            Expanded(
              child: _TrendCard(
                label: 'Net',
                value: CurrencyFormatter.money(review.netKes),
                delta: _deltaMoney(review.netDeltaKes),
                deltaColor: review.netDeltaKes >= 0
                    ? AppColors.success
                    : AppColors.danger,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.listGap),
            Expanded(
              child: _TrendCard(
                label: 'Task Rate',
                value:
                    '${(review.completionRateThisWeek * 100).toStringAsFixed(0)}%',
                delta: _deltaPercent(completionDelta),
                deltaColor:
                    completionDelta >= 0 ? AppColors.success : AppColors.warning,
                icon: Icons.task_alt_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaColor,
    required this.icon,
  });

  final String label;
  final String value;
  final String delta;
  final Color deltaColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tone: GlassCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.amount(context).copyWith(fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.bodySm(context)),
          const SizedBox(height: 6),
          Text(
            delta,
            style: AppTypography.bodySm(context).copyWith(
              color: deltaColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final WeekReviewInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.tone) {
      WeekReviewInsightTone.positive => AppColors.success,
      WeekReviewInsightTone.caution => AppColors.warning,
      WeekReviewInsightTone.neutral => AppColors.accent,
    };
    final icon = switch (insight.tone) {
      WeekReviewInsightTone.positive => Icons.check_circle_outline,
      WeekReviewInsightTone.caution => Icons.warning_amber_rounded,
      WeekReviewInsightTone.neutral => Icons.lightbulb_outline_rounded,
    };

    return GlassCard(
      tone: GlassCardTone.muted,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.xl),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: AppTypography.cardTitle(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insight.detail,
                            style: AppTypography.bodySm(context),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _deltaMoney(double delta) {
  final sign = delta >= 0 ? '+' : '−';
  // Keep short so it fits in a half-width card — no "vs last week" suffix
  return '$sign${CurrencyFormatter.money(delta.abs())}';
}

String _deltaPercent(double delta) {
  final sign = delta >= 0 ? '+' : '−';
  return '$sign${(delta.abs() * 100).toStringAsFixed(0)}%';
}
