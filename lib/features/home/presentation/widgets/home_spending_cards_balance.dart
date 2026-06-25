part of 'home_spending_cards.dart';

/// Simplified weekly spend headline card.
class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard({super.key, required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week', style: AppTypography.label(context)),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.money(overview.weekKes),
              style: AppTypography.amountLg(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${CurrencyFormatter.money(overview.todayKes)} today',
            style: AppTypography.bodySm(context),
          ),
        ],
      ),
    );
  }
}
