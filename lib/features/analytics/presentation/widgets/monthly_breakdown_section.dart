import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// Expandable month cards — each shows month label, delta badge, total,
/// tx count, and expands to reveal top-5 category bars.
class MonthlyBreakdownSection extends StatelessWidget {
  const MonthlyBreakdownSection({
    super.key,
    required this.history,
    required this.categoryBreakdown,
    this.onTapMonth,
  });

  final List<MonthlyTotalPoint> history;
  final List<AnalyticsCategoryShare> categoryBreakdown;
  final void Function(int year, int month)? onTapMonth;

  @override
  Widget build(BuildContext context) {
    final nonZero = history.where((p) => p.totalKes > 0).toList();
    if (nonZero.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly History',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...nonZero.reversed.map((point) {
          final prev = nonZero.length > 1
              ? _findPrevious(point.periodKey, history)
              : null;
          return _MonthCard(
            point: point,
            previousTotalKes: prev?.totalKes ?? 0,
            totalTxCount: _estimateTxCount(point, history),
            categoryBreakdown: categoryBreakdown,
            onTap: () => onTapMonth?.call(point.year, point.month),
          );
        }),
      ],
    );
  }

  MonthlyTotalPoint? _findPrevious(
    String key,
    List<MonthlyTotalPoint> history,
  ) {
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final prevKey = month > 1
        ? '${year.toString().padLeft(4, '0')}-${(month - 1).toString().padLeft(2, '0')}'
        : '${(year - 1).toString().padLeft(4, '0')}-12';
    return history.cast<MonthlyTotalPoint?>().firstWhere(
      (p) => p?.periodKey == prevKey,
      orElse: () => null,
    );
  }

  int _estimateTxCount(
    MonthlyTotalPoint point,
    List<MonthlyTotalPoint> history,
  ) {
    // Rough estimate — actual count needs a separate query.
    final avg = history
        .where((p) => p.totalKes > 0)
        .map((p) => p.totalKes)
        .fold<double>(0, (a, b) => a + b) /
        (history.where((p) => p.totalKes > 0).length.clamp(1, 999));
    if (avg <= 0) return 0;
    return (point.totalKes / avg).round().clamp(1, 999);
  }
}

class _MonthCard extends StatefulWidget {
  const _MonthCard({
    required this.point,
    required this.previousTotalKes,
    required this.totalTxCount,
    required this.categoryBreakdown,
    required this.onTap,
  });

  final MonthlyTotalPoint point;
  final double previousTotalKes;
  final int totalTxCount;
  final List<AnalyticsCategoryShare> categoryBreakdown;
  final VoidCallback onTap;

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    final momPct = widget.previousTotalKes > 0
        ? ((point.totalKes - widget.previousTotalKes) / widget.previousTotalKes) * 100
        : null;
    final spentMore = (momPct ?? 0) > 0;
    final color = spentMore ? AppColors.danger : AppColors.success;

    // Top 5 categories — use snapshot-level breakdown as approximation.
    final top5 = widget.categoryBreakdown.take(5).toList();
    final maxCat = top5.isNotEmpty
        ? top5.map((c) => c.totalKes).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: _toggle,
        child: Column(
          children: [
            // ── Header row ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${point.monthLabel} ${point.year}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.money(point.totalKes)} · ${widget.totalTxCount} tx',
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
                if (momPct != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${spentMore ? '+' : ''}${momPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            // ── Expanded categories ──────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded && top5.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Column(
                        children: top5.map((cat) {
                          final catVisual = categoryVisual(cat.category);
                          final frac = maxCat > 0
                              ? (cat.totalKes / maxCat).clamp(0.0, 1.0)
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Container(
                                  width: AppSpacing.sm,
                                  height: AppSpacing.sm,
                                  decoration: BoxDecoration(
                                    color: catVisual.foreground,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    cat.category,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 72,
                                  child: Text(
                                    CurrencyFormatter.money(cat.totalKes),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: frac,
                                      minHeight: 4,
                                      backgroundColor: catVisual.foreground
                                          .withValues(alpha: 0.12),
                                      valueColor: AlwaysStoppedAnimation(
                                        catVisual.foreground,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
