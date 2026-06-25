part of 'expenses_snapshot_content.dart';

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    this.tone = AppCardTone.standard,
    this.accentColor,
    this.delta,
    this.deltaIsGood,
  });

  final String title;
  final String amount;
  final AppCardTone tone;
  final Color? accentColor;
  // Optional week-over-week delta string, e.g. '+12%' or '-5%'.
  final String? delta;
  // True means spending went down (green), false means up (red).
  final bool? deltaIsGood;

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaIsGood == null
        ? AppColors.textMuted
        : (deltaIsGood! ? AppColors.success : AppColors.danger);
    return AppCard(
      tone: tone,
      accentColor: accentColor,
      child: SizedBox(
        height: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTypography.bodySm(context)),
                ),
                if (delta != null)
                  Text(
                    delta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.metaText(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, color: deltaColor),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: AppTypography.amount(context),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Budget Mini Card ──────────────────────────────────────────────────────────

class _BudgetMiniCard extends StatelessWidget {
  const _BudgetMiniCard({
    required this.budgetSnapshot,
    required this.monthTotal,
  });

  final BudgetSnapshot? budgetSnapshot;
  final double monthTotal;

  @override
  Widget build(BuildContext context) {
    final limit = budgetSnapshot?.totalLimitKes ?? 0.0;
    final hasBudget = limit > 0;
    final ratio = hasBudget ? (monthTotal / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = hasBudget && monthTotal > limit;
    final color = isOver
        ? AppColors.danger
        : (hasBudget && ratio >= 0.8)
        ? AppColors.warning
        : AppColors.accent;

    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget', style: AppTypography.bodySm(context)),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.money(monthTotal),
              style: AppTypography.amount(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasBudget
                ? 'of ${CurrencyFormatter.money(limit)}'
                : 'spent this month',
            style: AppTypography.bodySm(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasBudget) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: AppColors.textMuted.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Month-End Forecast Mini Card ──────────────────────────────────────────────

class _ForecastMiniCard extends StatelessWidget {
  const _ForecastMiniCard({required this.monthTotal});

  final double monthTotal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day.clamp(1, daysInMonth);
    final forecast = (monthTotal / dayOfMonth) * daysInMonth;

    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Month-end forecast', style: AppTypography.bodySm(context)),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.money(forecast),
              style: AppTypography.amount(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'at current pace',
            style: AppTypography.bodySm(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


