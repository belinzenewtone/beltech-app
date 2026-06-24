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
    final textTheme = Theme.of(context).textTheme;
    final items = widget.snapshot.items;
    final visibleItems = _showAll ? items : items.take(6).toList();
    final hasMore = items.length > 6;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Budget Usage', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '${CurrencyFormatter.money(widget.snapshot.totalSpentKes)} / ${CurrencyFormatter.money(widget.snapshot.totalLimitKes)}',
            style: textTheme.bodyLarge,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          const SizedBox(height: 8),
          for (final item in visibleItems) ...[
            _BudgetProgressRow(item: item),
            const SizedBox(height: 8),
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
              Text(item.category),
              const SizedBox(height: 4),
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
        const SizedBox(width: 10),
        Text(
          CurrencyFormatter.money(item.spentKes),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
        ),
      ],
    );
  }
}
