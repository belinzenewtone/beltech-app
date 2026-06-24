import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum GlassCardTone { standard, accent, muted }

/// Unified card component used across the entire app.
///
/// Design spec (matching RN reference):
/// - Flat, solid surfaces — no heavy glassmorphism blur
/// - Subtle 1px border only — minimal or no shadow
/// - Consistent 16px border radius (not too round, not too sharp)
/// - 16px internal padding by default
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.tone = GlassCardTone.standard,
    this.accentColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final GlassCardTone tone;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final effectiveAccent = accentColor ?? AppColors.accent;

    final bgColor = switch (tone) {
      GlassCardTone.accent => brightness == Brightness.light
          ? effectiveAccent.withValues(alpha: 0.10)
          : effectiveAccent.withValues(alpha: 0.22),
      GlassCardTone.muted => brightness == Brightness.light
          ? AppColors.surfaceMutedFor(brightness)
          : AppColors.surfaceMuted,
      GlassCardTone.standard => brightness == Brightness.light
          ? AppColors.surfaceFor(brightness)
          : AppColors.surfaceElevated,
    };

    final borderColor = switch (tone) {
      GlassCardTone.accent => effectiveAccent.withValues(alpha: 0.26),
      GlassCardTone.muted => brightness == Brightness.light
          ? AppColors.borderFor(brightness)
          : AppColors.border,
      GlassCardTone.standard => brightness == Brightness.light
          ? AppColors.borderFor(brightness)
          : AppColors.borderStrong,
    };

    final innerDecoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor),
      // Minimal elevation — no heavy shadow. RN uses flat cards with borders.
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    );

    Widget inner = Container(
      margin: margin,
      decoration: innerDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: inner,
        ),
      );
    }

    return inner;
  }
}
