import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Displays a trend indicator with up/down arrow and percentage change.
class TrendArrowIndicator extends StatelessWidget {
  const TrendArrowIndicator({
    super.key,
    required this.currentValue,
    required this.previousValue,
    this.label = 'vs last period',
  });

  final double currentValue;
  final double previousValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isPositive = currentValue > previousValue;
    final percentChange = previousValue > 0
        ? ((currentValue - previousValue) / previousValue * 100).abs()
        : 0.0;

    final color = isPositive ? AppColors.warning : AppColors.success;
    final icon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '${percentChange.toStringAsFixed(1)}%',
          style: AppTypography.bodySm(context).copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySm(context).copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
