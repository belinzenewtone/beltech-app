import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/review/domain/entities/monthly_wrapped_data.dart';
import 'package:beltech/features/review/presentation/providers/monthly_wrapped_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Monthly Wrapped screen — full month summary.
/// Mirrors Kotlin MonthlyWrappedScreen.
class MonthlyWrappedScreen extends ConsumerStatefulWidget {
  const MonthlyWrappedScreen({super.key, required this.year, required this.month});

  final int year;
  final int month;

  @override
  ConsumerState<MonthlyWrappedScreen> createState() =>
      _MonthlyWrappedScreenState();
}

class _MonthlyWrappedScreenState extends ConsumerState<MonthlyWrappedScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
  }

  void _prev() {
    setState(() {
      if (_month > 1) {
        _month--;
      } else {
        _month = 12;
        _year--;
      }
    });
  }

  void _next() {
    final now = DateTime.now();
    if (_year > now.year || (_year == now.year && _month >= now.month)) return;
    setState(() {
      if (_month < 12) {
        _month++;
      } else {
        _month = 1;
        _year++;
      }
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _year == now.year && _month == now.month;
  }

  Future<void> _shareCard(BuildContext context, WidgetRef ref) async {
    try {
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/monthly_wrapped_$_year-$_month.png').create();
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: 'My $_month/$_year Wrapped — Beltech');
    } catch (_) {
      // Share silently fails if user cancels
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(monthlyWrappedProvider((_year, _month)));
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final hasData = dataAsync.maybeWhen(data: (d) => d.hasData, orElse: () => false);

    final _shareKey = GlobalKey();

    return SecondaryPageShell(
      title: 'Monthly Wrapped',
      scrollable: false,
      child: Column(
        children: [
          // ── Month navigator ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: hasData ? _prev : null,
                ),
                Column(
                  children: [
                    Text(
                      '${monthNames[_month - 1]} $_year',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    dataAsync.maybeWhen(
                      data: (d) => Text(
                        '${d.txCount} transactions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: _isCurrentMonth ? Colors.grey.withOpacity(0.3) : null,
                  ),
                  onPressed: _isCurrentMonth ? null : _next,
                ),
                dataAsync.maybeWhen(
                  data: (d) => d.hasData
                      ? IconButton(
                          icon: const Icon(Icons.share_rounded, size: 20),
                          tooltip: 'Share as image',
                          onPressed: () => _shareCard(context, ref),
                        )
                      : null,
                  orElse: () => null,
                ) ?? const SizedBox.shrink(),
              ],
            ),
          ),
          // ── Content with swipe navigation ──────────────────────────────
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200) {
                  HapticFeedback.lightImpact();
                  _next();
                } else if (details.primaryVelocity! > 200 && hasData) {
                  HapticFeedback.lightImpact();
                  _prev();
                }
              },
              child: RepaintBoundary(
                child: dataAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (data) => data.hasData
                      ? _WrappedContent(data: data)
                      : _EmptyState(month: monthNames[_month - 1], year: _year),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main content
// ─────────────────────────────────────────────────────────────────────────────

class _WrappedContent extends StatelessWidget {
  const _WrappedContent({required this.data});
  final MonthlyWrappedData data;

  @override
  Widget build(BuildContext context) {
    const h = SizedBox(height: 10);
    final momPct = data.monthOverMonthPct;
    final spentMore = (momPct ?? 0) > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Total spend card ─────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spent',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.money(data.totalSpentKes),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (momPct != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        spentMore
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: spentMore ? AppColors.danger : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${spentMore ? '+' : ''}${momPct.toStringAsFixed(1)}% vs last month',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: spentMore ? AppColors.danger : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          h,
          // ── Top categories ───────────────────────────────────────────
          if (data.topCategories.isNotEmpty)
            _TopCategoriesCard(categories: data.topCategories, total: data.totalSpentKes),
          h,
          // ── Month highlights ─────────────────────────────────────────
          if (data.biggestTxMerchant != null || data.topMerchant != null)
            _MonthHighlightsCard(data: data),
          h,
          // ── Active days + fees (side-by-side) ────────────────────────
          if (data.activeDays > 0 || data.feesPaidKes > 0)
            Row(
              children: [
                if (data.activeDays > 0)
                  Expanded(
                    child: _StatMiniCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Active days',
                      value: '${data.activeDays} / ${data.daysInMonth}',
                    ),
                  ),
                if (data.activeDays > 0 && data.feesPaidKes > 0)
                  const SizedBox(width: 10),
                if (data.feesPaidKes > 0)
                  Expanded(
                    child: _StatMiniCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'Fees paid',
                      value: CurrencyFormatter.money(data.feesPaidKes),
                    ),
                  ),
              ],
            ),
          // ── Fuliza card ──────────────────────────────────────────────
          if (data.fulizaUsedCount > 0) ...[
            h,
            AppCard(
              accentColor: AppColors.danger,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fuliza Used',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${data.fulizaUsedCount}× · ${CurrencyFormatter.money(data.fulizaTotal)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Try to keep this below 3 times per month.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.danger.withOpacity(0.7),
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // ── Saved / overspent verdict ────────────────────────────────
          if (data.incomeTotalKes > 0) ...[
            h,
            _VerdictCard(data: data),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top categories card with rank badges
// ─────────────────────────────────────────────────────────────────────────────

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({required this.categories, required this.total});
  final List<WrappedCategoryRow> categories;
  final double total;

  static const _rankColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...categories.map((cat) {
            final visual = categoryVisual(cat.category);
            final frac = total > 0 ? (cat.totalKes / total).clamp(0.0, 1.0) : 0.0;
            final rankColor = cat.rank <= 3
                ? _rankColors[cat.rank - 1]
                : Theme.of(context).colorScheme.outline;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cat.rank}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: rankColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: visual.foreground,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cat.category,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.money(cat.totalKes),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 5,
                      backgroundColor: visual.foreground.withOpacity(0.12),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(visual.foreground),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month highlights card
// ─────────────────────────────────────────────────────────────────────────────

class _MonthHighlightsCard extends StatelessWidget {
  const _MonthHighlightsCard({required this.data});
  final MonthlyWrappedData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Month Highlights',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (data.biggestTxMerchant != null)
            _HighlightRow(
              icon: Icons.bolt_rounded,
              label: 'Biggest spend',
              value:
                  '${data.biggestTxMerchant} — ${CurrencyFormatter.money(data.biggestTxAmount)}',
            ),
          if (data.topMerchant != null) ...[
            const SizedBox(height: 8),
            _HighlightRow(
              icon: Icons.store_rounded,
              label: 'Most visited',
              value:
                  '${data.topMerchant} (${data.topMerchantCount}×)',
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini stat card (active days / fees)
// ─────────────────────────────────────────────────────────────────────────────

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verdict card (saved / overspent)
// ─────────────────────────────────────────────────────────────────────────────

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.data});
  final MonthlyWrappedData data;

  @override
  Widget build(BuildContext context) {
    final saved = data.savedKes;
    final color = data.isOverBudget ? AppColors.danger : AppColors.success;
    final icon = data.isOverBudget
        ? Icons.trending_up_rounded
        : Icons.savings_rounded;
    final title = data.isOverBudget ? 'Overspent' : 'Saved this month';
    final subtitle = data.isOverBudget
        ? 'You spent ${CurrencyFormatter.money(saved.abs())} more than income.'
        : 'Great job! You kept ${CurrencyFormatter.money(saved)} from income.';
    final breakdown = 'Income KSh ${CurrencyFormatter.money(data.incomeTotalKes)} · Spend KSh ${CurrencyFormatter.money(data.totalSpentKes)}';

    return AppCard(
      accentColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: color)),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        )),
                const SizedBox(height: 2),
                Text(breakdown,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontSize: 11,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.month, required this.year});
  final String month;
  final int year;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 52,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No data for $month $year',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions for this month will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
