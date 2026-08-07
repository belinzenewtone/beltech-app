import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filtered transaction list scoped to a single category + period.
/// Accessed by tapping a CategoryCard in CategorySpendCards.
/// Receives the full [AnalyticsCategoryShare] via GoRouter `extra`.
class CategoryDrillDownScreen extends ConsumerStatefulWidget {
  const CategoryDrillDownScreen({
    super.key,
    required this.category,
    required this.totalKes,
    this.txCount = 0,
    this.share,
  });

  final String category;
  final double totalKes;
  final int txCount;

  /// Full share object injected from route extra — provides sparkline +
  /// top merchant + percentage. Optional for backwards compatibility.
  final AnalyticsCategoryShare? share;

  @override
  ConsumerState<CategoryDrillDownScreen> createState() =>
      _CategoryDrillDownScreenState();
}

class _CategoryDrillDownScreenState
    extends ConsumerState<CategoryDrillDownScreen> {
  late Future<List<CategoryTransaction>> _txnsFuture;

  @override
  void initState() {
    super.initState();
    _txnsFuture = _load();
  }

  Future<List<CategoryTransaction>> _load() {
    final now = DateTime.now();
    return ref
        .read(analyticsRepositoryProvider)
        .getCategoryTransactions(
          widget.category,
          start: DateTime(now.year - 2, 1, 1),
        );
  }

  void _reload() {
    setState(() {
      _txnsFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(widget.category);

    return SecondaryPageShell(
      title: widget.category,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Summary header ─────────────────────────────────────────────
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl - 4),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: visual.foreground.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      visual.icon,
                      size: 28,
                      color: visual.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    CurrencyFormatter.money(widget.totalKes),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: visual.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FutureBuilder<List<CategoryTransaction>>(
                    future: _txnsFuture,
                    builder: (context, snapshot) {
                      final txns = snapshot.data;
                      final count = txns != null ? txns.length : widget.txCount;
                      return Text(
                        '$count transactions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // ── Percentage + top merchant (from real share data) ─────────────
            if (widget.share != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.share!.percentage.toStringAsFixed(1)}% of period spend',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                          ),
                          if (widget.share!.topMerchant != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Top merchant: ${widget.share!.topMerchant}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // ── 8-week sparkline trend ─────────────────────────────────────────
            if (widget.share != null &&
                widget.share!.weeklySparkline.any((v) => v > 0)) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '8-Week Trend',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 48,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: widget.share!.weeklySparkline.map((v) {
                          final maxV = widget.share!.weeklySparkline
                              .fold<double>(0, (a, b) => b > a ? b : a);
                          final frac = maxV > 0
                              ? (v / maxV).clamp(0.0, 1.0)
                              : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Container(
                                height: 8 + frac * 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      visual.foreground,
                                      visual.foreground.withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '7 wks ago',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 9,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                        ),
                        Text(
                          'This week',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 9,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // ── Real transaction list ─────────────────────────────────────────
            Text(
              'Transactions',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<CategoryTransaction>>(
              future: _txnsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text('Unable to load transactions: ${snapshot.error}'),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }
                final txns = snapshot.data ?? const [];
                if (txns.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No transactions in this category.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                return AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < txns.length; i++) ...[
                        if (i > 0) const Divider(height: 16),
                        _DrillDownRow(
                          title: txns[i].title,
                          amount: txns[i].amountKes,
                          date: _formatDate(txns[i].occurredAt),
                          visual: visual,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} · $h:$m';
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
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
