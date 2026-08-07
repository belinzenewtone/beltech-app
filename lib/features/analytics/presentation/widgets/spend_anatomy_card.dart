import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/chart_semantics.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// Spend Anatomy card — shows distribution of transaction sizes.
/// Bars animate on entry with staggered timing.
class SpendAnatomyCard extends StatefulWidget {
  const SpendAnatomyCard({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  State<SpendAnatomyCard> createState() => _SpendAnatomyCardState();
}

class _SpendAnatomyCardState extends State<SpendAnatomyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.snapshot.microTxCount +
        widget.snapshot.mediumTxCount +
        widget.snapshot.largeTxCount;
    if (total == 0) return const SizedBox.shrink();

    final microPct = (widget.snapshot.microTxCount / total * 100).toStringAsFixed(0);
    final medPct = (widget.snapshot.mediumTxCount / total * 100).toStringAsFixed(0);
    final largePct = (widget.snapshot.largeTxCount / total * 100).toStringAsFixed(0);

    return ChartSemantics(
      label: 'Spend anatomy: $microPct% micro under KES 500, $medPct% medium KES 500–2000, $largePct% large over KES 2000',
      child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spend Anatomy',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'How your $total transactions break down by size',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 16),
          _AnatomyBar(
            label: 'Micro',
            sublabel: '< KES 500',
            count: widget.snapshot.microTxCount,
            total: total,
            color: AppColors.success,
            controller: _controller,
            staggerDelay: 0,
          ),
          const SizedBox(height: 10),
          _AnatomyBar(
            label: 'Medium',
            sublabel: 'KES 500–2k',
            count: widget.snapshot.mediumTxCount,
            total: total,
            color: const Color(0xFFF59E0B),
            controller: _controller,
            staggerDelay: 80,
          ),
          const SizedBox(height: 10),
          _AnatomyBar(
            label: 'Large',
            sublabel: '> KES 2k',
            count: widget.snapshot.largeTxCount,
            total: total,
            color: AppColors.danger,
            controller: _controller,
            staggerDelay: 160,
          ),
        ],
      ),
    ), // AppCard
    ); // ChartSemantics
  }
}

class _AnatomyBar extends StatelessWidget {
  const _AnatomyBar({
    required this.label,
    required this.sublabel,
    required this.count,
    required this.total,
    required this.color,
    required this.controller,
    required this.staggerDelay,
  });

  final String label;
  final String sublabel;
  final int count;
  final int total;
  final Color color;
  final AnimationController controller;
  final int staggerDelay;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final pct = (fraction * 100).toStringAsFixed(0);
    final intervalStart = staggerDelay / controller.duration!.inMilliseconds.toDouble();
    final barAnim = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, (intervalStart + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
            Text(
              '$count tx · $pct%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: barAnim,
            builder: (_, child) => LinearProgressIndicator(
              value: fraction * barAnim.value,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
