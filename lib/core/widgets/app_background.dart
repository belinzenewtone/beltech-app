import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Atmospheric background painted behind every screen.
///
/// Renders the base background colour plus two soft radial "glows" (blue
/// top-left, teal bottom-right). These glows give the frosted-glass surfaces
/// something to refract, so the [BackdropFilter] blur is actually visible
/// instead of blurring a flat solid colour.
///
/// Usage — wrap as the outermost layer of a screen, then place scrollable
/// content on top (content stays transparent so the atmosphere shows through):
/// ```dart
/// RepaintBoundary(child: AppBackground(child: SafeArea(child: scrollView)))
/// ```
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.brightness, this.child});

  /// Forces a specific brightness. When omitted, resolves from [Theme].
  final Brightness? brightness;

  /// Optional content painted on top of the atmosphere.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final b = brightness ?? Theme.of(context).brightness;
    final glows = b == Brightness.light
        ? <Widget>[
            _Glow(
              color: AppColors.accent.withValues(alpha: 0.10),
              center: const Alignment(-0.55, -0.7),
              radius: 0.9,
            ),
            _Glow(
              color: AppColors.teal.withValues(alpha: 0.08),
              center: const Alignment(0.6, 0.85),
              radius: 0.85,
            ),
          ]
        : <Widget>[
            const _Glow(
              color: AppColors.glowBlue,
              center: Alignment(-0.5, -0.75),
              radius: 0.95,
            ),
            const _Glow(
              color: AppColors.glowTeal,
              center: Alignment(0.65, 0.8),
              radius: 0.9,
            ),
          ];

    return ColoredBox(
      color: AppColors.backgroundFor(b),
      child: Stack(
        children: [
          // Each glow paints once (RepaintBoundary) instead of re-rasterizing
          // the full-screen radial gradient every frame the content above it
          // scrolls — a meaningful GPU saving on low-end devices.
          for (final glow in glows) RepaintBoundary(child: glow),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.center, required this.radius});

  final Color color;
  final Alignment center;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: radius,
            colors: [color, const Color(0x00000000)],
            stops: const [0.0, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
