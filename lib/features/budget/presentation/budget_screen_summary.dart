part of 'budget_screen.dart';

class _BudgetSummaryCard extends StatefulWidget {
  const _BudgetSummaryCard({required this.snapshot});

  final BudgetSnapshot snapshot;

  @override
  State<_BudgetSummaryCard> createState() => _BudgetSummaryCardState();
}

class _BudgetSummaryCardState extends State<_BudgetSummaryCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.snapshot.items;
    final visibleItems = _showAll ? items : items.take(6).toList();
    final hasMore = items.length > 6;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Budget Usage',
            style: AppTypography.sectionTitle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${CurrencyFormatter.money(widget.snapshot.totalSpentKes)} / ${CurrencyFormatter.money(widget.snapshot.totalLimitKes)}',
            style: AppTypography.headlineSm(context),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in visibleItems) ...[
            _BudgetProgressRow(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (hasMore)
            TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                _showAll
                    ? 'Show fewer'
                    : 'Show all categories (${items.length})',
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetProgressRow extends StatelessWidget {
  const _BudgetProgressRow({required this.item});

  final BudgetCategoryItem item;

  @override
  Widget build(BuildContext context) {
    final exceeded = item.spentKes > item.monthlyLimitKes;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.category, style: AppTypography.bodySm(context)),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: item.usageRatio,
                minHeight: 6,
                borderRadius: BorderRadius.circular(100),
                backgroundColor: AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  exceeded ? AppColors.danger : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          CurrencyFormatter.money(item.spentKes),
          style: AppTypography.bodySm(context),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
        ),
      ],
    );
  }
}
