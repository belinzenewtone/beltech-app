import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/chart_semantics.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// Payday Pulse card — compares avg daily spend in 7 days post-income
/// vs other days. Includes screen-reader semantics.
class PaydayPulseCard extends StatelessWidget {
  const PaydayPulseCard({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final post = snapshot.postIncomeAvgDailySpendKes;
    final other = snapshot.otherDaysAvgDailySpendKes;
    if (post == null || other == null) return const SizedBox.shrink();

    final maxVal = [post, other].reduce((a, b) => a > b ? a : b);
    final postFrac = maxVal > 0 ? (post / maxVal).clamp(0.0, 1.0) : 0.0;
    final otherFrac = maxVal > 0 ? (other / maxVal).clamp(0.0, 1.0) : 0.0;
    final postHigher = post > other;
    final incomeCount = snapshot.incomeEventsCount ?? 0;
    final pctDiff = other > 0
        ? (((post - other) / other) * 100).abs().toStringAsFixed(0)
        : null;

    return ChartSemantics(
      label: 'Payday Pulse: post-income ${CurrencyFormatter.compact(post)} per day, other days ${CurrencyFormatter.compact(other)}',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payday Pulse',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '$incomeCount income events · avg daily spend',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 16),
            _PulseBar(
              label: 'Post-income (7 days)',
              fraction: postFrac,
              amount: post,
              color: postHigher ? AppColors.danger : AppColors.success,
              index: 0,
            ),
            const SizedBox(height: 10),
            _PulseBar(
              label: 'Other days',
              fraction: otherFrac,
              amount: other,
              color: !postHigher ? AppColors.danger : AppColors.success,
              index: 1,
            ),
            if (pctDiff != null) ...[
              const SizedBox(height: 12),
              Text(
                postHigher
                    ? 'You spend $pctDiff% more in the 7 days after income arrives.'
                    : 'You spend $pctDiff% less in the 7 days after income — disciplined!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: postHigher ? AppColors.warning : AppColors.success,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated pulse bar — fills from 0 → fraction over 500 ms with a per-bar
/// stagger delay of 120 ms × index so bars enter sequentially.
class _PulseBar extends StatefulWidget {
  const _PulseBar({
    required this.label,
    required this.fraction,
    required this.amount,
    required this.color,
    required this.index,
  });

  final String label;
  final double fraction;
  final double amount;
  final Color color;

  /// Bar position (0-based); drives the stagger delay.
  final int index;

  @override
  State<_PulseBar> createState() => _PulseBarState();
}

class _PulseBarState extends State<_PulseBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0, end: widget.fraction).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // Stagger: each bar waits 120 ms × its index before starting.
    Future.delayed(Duration(milliseconds: 120 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            Text(
              '${CurrencyFormatter.money(widget.amount)}/day',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _anim.value,
              minHeight: 8,
              backgroundColor: widget.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
        ),
      ],
    );
  }
}
