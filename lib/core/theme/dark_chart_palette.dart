import 'package:flutter/material.dart';

/// Dark-mode chart colours that differ from light mode for contrast.
///
/// Consumed as a `ThemeExtension`:
/// ```dart
/// final dp = Theme.of(context).extension<DarkChartPalette>();
/// ```
class DarkChartPalette extends ThemeExtension<DarkChartPalette> {
  const DarkChartPalette({
    required this.danger,
    required this.success,
    required this.warning,
    required this.info,
    required this.surfaceFill,
  });

  // Light-mode defaults (safe daytime values, no change from base)
  static const light = DarkChartPalette(
    danger: Color(0xFFEF4444),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
    surfaceFill: Color(0xFFF1F5FB),
  );

  // Dark-mode values — warmer red, more saturated green, distinct from light
  static const dark = DarkChartPalette(
    danger: Color(0xFFFF6B6B),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    surfaceFill: Color(0xFF1E2936),
  );

  final Color danger;
  final Color success;
  final Color warning;
  final Color info;
  final Color surfaceFill;

  @override
  DarkChartPalette copyWith({
    Color? danger,
    Color? success,
    Color? warning,
    Color? info,
    Color? surfaceFill,
  }) {
    return DarkChartPalette(
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      surfaceFill: surfaceFill ?? this.surfaceFill,
    );
  }

  @override
  DarkChartPalette lerp(ThemeExtension<DarkChartPalette>? other, double t) {
    if (other is! DarkChartPalette) return this;
    return DarkChartPalette(
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      surfaceFill: Color.lerp(surfaceFill, other.surfaceFill, t)!,
    );
  }
}
