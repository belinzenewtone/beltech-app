import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Centralized glassmorphism appearance tokens.
///
/// Single source of truth for the frosted-glass surface treatment used by
/// [AppCard], [AppFormSheet], and the floating tab bar. Keeping these values
/// here guarantees every glass surface in the app looks identical — which is
/// the core of a consistent, modern design language.
///
/// Per CODING_RULES CR-06: glass surfaces use [BackdropFilter] blur, rounded
/// corners, and translucent fills. Per CR-07: shared style tokens live under
/// `core/theme/`.
class GlassStyles {
  const GlassStyles._();

  // ── Blur sigma ──────────────────────────────────────────────────────────────

  /// Blur strength for standard glass cards.
  static const double cardBlurSigma = 16.0;

  /// Blur strength for bottom sheets / dialogs (slightly stronger).
  static const double sheetBlurSigma = 20.0;

  /// Blur strength for the floating navigation bar. Kept moderate (7) — a
  /// full-width persistent blur re-composites the screen behind it every
  /// frame, so high sigma here is the #1 stutter source during scroll. At
  /// 56px height the visual difference between 14 and 7 is negligible.
  static const double tabBarBlurSigma = 7.0;

  // ── Translucent fills (alpha kept low so the blur is visible) ────────────────

  /// Translucent fill for a standard glass surface.
  static Color fillFor(Brightness brightness) =>
      brightness == Brightness.light
          ? const Color(0xB8FFFFFF) // white @ 72%
          : const Color(0x0DFFFFFF); // white @ 5%

  /// Translucent fill for a muted / lower-emphasis glass surface.
  static Color mutedFillFor(Brightness brightness) =>
      brightness == Brightness.light
          ? const Color(0xA6F1F5FB) // frosted slate @ 65%
          : const Color(0x12FFFFFF); // white @ 7%

  /// Accent-tinted translucent fill for emphasis cards.
  static Color accentFillFor(Brightness brightness, Color accent) =>
      brightness == Brightness.light
          ? accent.withValues(alpha: 0.14)
          : accent.withValues(alpha: 0.20);

  /// Higher-opacity fill for navigation bars / toolbars where label legibility
  /// matters more than translucency.
  static Color barFillFor(Brightness brightness) =>
      brightness == Brightness.light
          ? const Color(0xD9FFFFFF) // white @ 85%
          : AppColors.surface.withValues(alpha: 0.72);

  // ── Borders ──────────────────────────────────────────────────────────────────

  /// Hairline border for glass surfaces — a faint light edge that catches light
  /// and separates the card from the background.
  static Color borderFor(Brightness brightness) =>
      brightness == Brightness.light
          ? const Color(0x55FFFFFF) // white @ 33%
          : const Color(0x14FFFFFF); // white @ 8%

  // ── Shadows ──────────────────────────────────────────────────────────────────

  /// Soft elevation shadow for glass surfaces.
  static List<BoxShadow> shadowFor(Brightness brightness) =>
      brightness == Brightness.light
          ? const [
              BoxShadow(
                color: Color(0x14000000), // 8%
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x47000000), // 28%
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ];
}
