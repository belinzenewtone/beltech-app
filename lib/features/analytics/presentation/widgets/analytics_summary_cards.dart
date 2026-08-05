import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/animated_number.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// 2×2 grid of summary metric cards — animated countup + velocity sparkline.
class AnalyticsSummaryCards extends StatelessWidget {
  const AnalyticsSummaryCards({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final net = snapshot.netKes;
    final showSparkline = snapshot.weeklySpending.isNotEmpty &&
        snapshot.weeklySpending.any((p) => p.amountKes > 0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Spend',
                rawValue: snapshot.totalSpentThisPeriodKes,
                color: AppColors.danger,
                sparklineData: showSparkline
                    ? snapshot.weeklySpending.map((p) => p.amountKes).toList()
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                rawValue: snapshot.totalIncomeThisPeriodKes,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Net',
                rawValue: net.abs(),
                prefix: net >= 0 ? '+' : '-',
                color: net >= 0 ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Avg Tx',
                rawValue: snapshot.avgTransactionKes,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.rawValue,
    required this.color,
    this.prefix = '',
    this.sparklineData,
  });

  final String label;
  final double rawValue;
  final Color color;
  final String prefix;
  final List<double>? sparklineData;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 4),
          AnimatedNumber(
            value: rawValue,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutExpo,
            formatter: (v) => '$prefix${CurrencyFormatter.compact(v)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (sparklineData != null && sparklineData!.any((v) => v > 0)) ...[
            const SizedBox(height: 8),
            _VelocitySparkline(data: sparklineData!, color: color),
          ],
        ],
      ),
    );
  }
}

/// 32px sparkline — quadratic Bezier curve with area fill.
class _VelocitySparkline extends StatelessWidget {
  const _VelocitySparkline({required this.data, required this.color});
  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 32,
      child: CustomPaint(
        size: const Size(double.infinity, 32),
        painter: _SparklinePainter(data: data, maxVal: maxVal, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.data, required this.maxVal, required this.color});
  final List<double> data;
  final double maxVal;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxVal <= 0) return;
    final stepX = size.width / (data.length - 1).clamp(1, 999);
    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final h = maxVal > 0 ? (data[i] / maxVal).clamp(0.0, 1.0) * size.height * 0.8 : 0.0;
      points.add(Offset(x, size.height - h));
    }
    if (points.isEmpty) return;
    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    for (var i = 0; i < points.length - 1; i++) {
      final mid = Offset((points[i].dx + points[i + 1].dx) / 2, (points[i].dy + points[i + 1].dy) / 2);
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      fillPath.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.18)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      data != old.data || maxVal != old.maxVal || color != old.color;
}
