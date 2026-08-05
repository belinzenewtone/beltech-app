import 'dart:math' as math;
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/section_header.dart';
import 'package:beltech/features/analytics/presentation/widgets/category_manager_sheet.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Expandable category spend cards — top 3 shown initially, expand up to 8.
/// Each card includes a mini 8-week sparkline and the top merchant.
/// Mirrors Kotlin CategorySpendCards in InsightsScreen Analytics tab.
class CategorySpendCards extends ConsumerStatefulWidget {
  const CategorySpendCards({
    super.key,
    required this.categories,
  });

  final List<AnalyticsCategoryShare> categories;

  @override
  ConsumerState<CategorySpendCards> createState() => _CategorySpendCardsState();
}

class _CategorySpendCardsState extends ConsumerState<CategorySpendCards> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.categories
        .where((c) => c.totalKes > 0)
        .take(_expanded ? 8 : 3)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Categories',
          action: TextButton(
            onPressed: () => showCategoryManagerSheet(context),
            child: const Text('Edit'),
          ),
        ),
        ...items.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CategoryCard(share: cat),
            )),
        if (widget.categories.where((c) => c.totalKes > 0).length > 3)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
              ),
              label: Text(_expanded ? 'Show less' : 'Show more'),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.share});

  final AnalyticsCategoryShare share;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(share.category);
    final pct = share.percentage.toStringAsFixed(1);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Colored dot indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: visual.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          // Category info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _titleCase(share.category),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.money(share.totalKes),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$pct% of spend',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.55),
                          ),
                    ),
                    if (share.topMerchant != null &&
                        share.topMerchant!.isNotEmpty) ...[
                      Text(
                        '  ·  Top: ${share.topMerchant}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.45),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                // Sparkline
                if (share.weeklySparkline.isNotEmpty &&
                    share.weeklySparkline.any((v) => v > 0)) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 28,
                    child: _Sparkline(
                      data: share.weeklySparkline,
                      color: visual.foreground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Mini bar sparkline — 8 weeks, each bar proportional to global max.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (prev, v) => v > prev ? v : prev);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((v) {
        final frac = maxVal > 0 ? (v / maxVal).clamp(0.0, 1.0) : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              height: math.max(2, frac * 24),
              decoration: BoxDecoration(
                color: v > 0 ? color.withOpacity(0.7) : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
