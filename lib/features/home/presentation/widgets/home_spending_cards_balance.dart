part of 'home_spending_cards.dart';

/// Weekly spend vs today spend balance summary card.
class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard({super.key, required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tone: GlassCardTone.accent,
      accentColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spend', style: AppTypography.bodySm(context)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.money(overview.weekKes),
                        style: AppTypography.amountLg(context),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
              const AppCapsule(
                label: 'Current',
                color: AppColors.success,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HomeBalanceStat(
                label: 'This Week',
                value: CurrencyFormatter.money(overview.weekKes),
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.cardGap),
              _HomeBalanceStat(
                label: 'Today',
                value: CurrencyFormatter.money(overview.todayKes),
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeBalanceStat extends StatelessWidget {
  const _HomeBalanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySm(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMd(context)
                .copyWith(fontWeight: FontWeight.w600, color: color),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ],
      ),
    );
  }
}
