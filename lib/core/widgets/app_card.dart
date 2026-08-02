import 'dart:ui';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:flutter/material.dart';

enum AppCardTone { standard, accent, muted }

/// Unified glass-style card used across the entire app.
///
/// Design spec (CODING_RULES CR-06 — glassmorphism):
/// - Translucent fill + hairline light border + soft shadow = the frosted-glass
///   aesthetic.
/// - Real [BackdropFilter] blur is **opt-in** via [blur] because it is very
///   expensive on the GPU (re-blurs every frame while scrolling). It should be
///   reserved for a few hero/featured cards per screen — not the 96 list/cards
///   rendered across the app. Defaulting to `false` keeps the visual language
///   consistent while staying smooth at 60fps.
/// - Consistent crisp corners (default 8) and 16px internal padding.
///
/// Because this is the single card component used everywhere, every screen
/// inherits the same surface treatment automatically.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 8,
    this.tone = AppCardTone.standard,
    this.accentColor,
    this.onTap,
    this.blur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final AppCardTone tone;
  final Color? accentColor;
  final VoidCallback? onTap;

  /// When `true`, wraps the surface in a real [BackdropFilter] blur. Expensive
  /// — use only for a small number of hero/featured cards per screen.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final effectiveAccent = accentColor ?? AppColors.accent;
    final radius = BorderRadius.circular(borderRadius);

    final fillColor = switch (tone) {
      AppCardTone.accent =>
        GlassStyles.accentFillFor(brightness, effectiveAccent),
      AppCardTone.muted => GlassStyles.mutedFillFor(brightness),
      AppCardTone.standard => GlassStyles.fillFor(brightness),
    };
    final borderColor = switch (tone) {
      AppCardTone.accent => effectiveAccent.withValues(
        alpha: brightness == Brightness.light ? 0.30 : 0.22,
      ),
      _ => GlassStyles.borderFor(brightness),
    };

    final surfaceDecoration = BoxDecoration(
      color: fillColor,
      borderRadius: radius,
      border: Border.all(color: borderColor),
    );

    // Shadow sits on the outer (un-clipped) layer so it is not cropped.
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: GlassStyles.shadowFor(brightness),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: blur
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: GlassStyles.cardBlurSigma,
                  sigmaY: GlassStyles.cardBlurSigma,
                ),
                child: DecoratedBox(
                  decoration: surfaceDecoration,
                  child: Padding(padding: padding, child: child),
                ),
              )
            : DecoratedBox(
                decoration: surfaceDecoration,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: surface,
        ),
      );
    }

    return surface;
  }
}
