import 'package:flutter/material.dart';

/// Theme-aware illustrated empty state using CustomPainter sketches.
/// Shows a bar chart + magnifier, a calendar + question, or a clock + check
/// depending on the variant.
class AnalyticsEmptyState extends StatelessWidget {
  const AnalyticsEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.variant = EmptyVariant.chart,
  });

  final String title;
  final String subtitle;
  final EmptyVariant variant;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              height: 80,
              child: CustomPaint(
                painter: _EmptyStatePainter(
                  variant: variant,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum EmptyVariant { chart, calendar, clock }

class _EmptyStatePainter extends CustomPainter {
  _EmptyStatePainter({required this.variant, required this.color});
  final EmptyVariant variant;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    switch (variant) {
      case EmptyVariant.calendar:
        _drawCalendar(canvas, w, h, paint, fillPaint);
      case EmptyVariant.clock:
        _drawClock(canvas, w, h, paint);
      case EmptyVariant.chart:
        _drawBarChart(canvas, w, h, paint, fillPaint);
    }
  }

  void _drawBarChart(Canvas canvas, double w, double h, Paint paint, Paint fillPaint) {
    // 4 bars: 2 tall + 1 short + 1 tall, centered
    final barGap = w * 0.08;
    final barCount = 4.0;
    final barW = (w - barGap * (barCount - 1)) / barCount;
    final barX = (w - (barW * barCount + barGap * (barCount - 1))) / 2;
    final barHeights = [h * 0.55, h * 0.8, h * 0.35, h * 0.65];

    for (int i = 0; i < barHeights.length; i++) {
      final x = barX + i * (barW + barGap);
      final barH = barHeights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, h - barH, barW, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, paint);
    }

    // Magnifier circle over the tallest bar
    final magPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final magX = barX + 1 * (barW + barGap) + barW / 2;
    final magY = h - h * 0.8 - 16;
    canvas.drawCircle(Offset(magX, magY), 12, magPaint);
    // Handle line
    canvas.drawLine(Offset(magX + 10, magY + 10), Offset(magX + 16, magY + 16), magPaint);
  }

  void _drawCalendar(Canvas canvas, double w, double h, Paint paint, Paint fillPaint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.1, w * 0.6, h * 0.8),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, paint);
    // Header bar
    final headerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.1, w * 0.6, h * 0.22),
        const Radius.circular(6),
      ),
      headerPaint,
    );
    // Question mark
    final qPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cx = w / 2;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, h * 0.45), radius: 10), -0.8, 3.14, false, qPaint);
    canvas.drawLine(Offset(cx, h * 0.45 + 5), Offset(cx, h * 0.62), qPaint);
    canvas.drawCircle(Offset(cx, h * 0.68), 1.5, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  void _drawClock(Canvas canvas, double w, double h, Paint paint) {
    final cx = w / 2, cy = h / 2, r = h * 0.4;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    // Hands
    canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.4, cy - r * 0.2), paint);
    canvas.drawLine(Offset(cx, cy), Offset(cx - r * 0.2, cy - r * 0.5), paint);
    // Checkmark
    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(cx - 8, cy + r * 0.3)
      ..lineTo(cx, cy + r * 0.55)
      ..lineTo(cx + 12, cy + r * 0.1);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _EmptyStatePainter oldDelegate) =>
      variant != oldDelegate.variant || color != oldDelegate.color;
}
