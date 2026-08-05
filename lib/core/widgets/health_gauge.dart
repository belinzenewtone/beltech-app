import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated semi-circular health gauge.
///
/// Draws a 180° arc (left→right) with:
///   • A faint background track
///   • A colour-graduated score arc that animates from 0 → score/100 on mount
///   • The numeric score + tier label centred below the arc
///
/// Usage:
/// ```dart
/// HealthGauge(score: 78, tierLabel: 'Good')
/// ```
class HealthGauge extends StatefulWidget {
  const HealthGauge({
    super.key,
    required this.score,
    required this.tierLabel,
  });

  /// Health score 0–100.
  final int score;

  /// Human-readable tier, e.g. "Good", "Excellent".
  final String tierLabel;

  @override
  State<HealthGauge> createState() => _HealthGaugeState();
}

class _HealthGaugeState extends State<HealthGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void didUpdateWidget(HealthGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Arc colour interpolated from red (0) → amber (50) → green (100).
  Color _gaugeColor(int score) {
    if (score >= 80) return const Color(0xFF16A34A); // green
    if (score >= 60) return const Color(0xFF65A30D); // lime-green
    if (score >= 40) return const Color(0xFFCA8A04); // amber
    return const Color(0xFFDC2626);                  // red
  }

  @override
  Widget build(BuildContext context) {
    final color = _gaugeColor(widget.score);
    final fraction = (widget.score / 100).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final animFraction = fraction * _anim.value;
        final animScore = (widget.score * _anim.value).round();

        return SizedBox(
          width: 180,
          height: 100,
          child: CustomPaint(
            painter: _GaugePainter(
              fraction: animFraction,
              color: color,
              trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Align(
              alignment: const Alignment(0, 1.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$animScore',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.tierLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  static const double _strokeWidth = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.92; // arc base sits near bottom
    final radius = (size.width / 2) - _strokeWidth / 2;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background track — half circle from π (left) sweeping π radians (to right).
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // Score arc
    if (fraction > 0) {
      final scorePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, math.pi, math.pi * fraction, false, scorePaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor;
}
