import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:flutter/material.dart';

/// Filtered transaction list scoped to a single category + period.
/// Accessed via long-press / chevron on a CategorySpendCard.
class CategoryDrillDownScreen extends StatelessWidget {
  const CategoryDrillDownScreen({
    super.key,
    required this.category,
    required this.totalKes,
    this.txCount = 0,
  });

  final String category;
  final double totalKes;
  final int txCount;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(category);

    return SecondaryPageShell(
      title: category,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary header ─────────────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: visual.foreground.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visual.icon, size: 28, color: visual.foreground),
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.money(totalKes),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: visual.foreground,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$txCount transactions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Transaction list (placeholder) ─────────────────────────────
          // Wired to real repo query in provider step.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent $category',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  txCount.clamp(0, 5),
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DrillDownRow(
                      title: '$category transaction #${i + 1}',
                      amount: totalKes / (txCount.clamp(1, 999)),
                      date: 'Aug ${i + 1}',
                      visual: visual,
                    ),
                  ),
                ),
                if (txCount == 0)
                  Text(
                    'No transactions yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
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

class _DrillDownRow extends StatelessWidget {
  const _DrillDownRow({
    required this.title,
    required this.amount,
    required this.date,
    required this.visual,
  });

  final String title;
  final double amount;
  final String date;
  final ({IconData icon, Color foreground, Color background}) visual;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: visual.foreground,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
              ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.money(amount),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: visual.foreground,
              ),
        ),
      ],
    );
  }
}
