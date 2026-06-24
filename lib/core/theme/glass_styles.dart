import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

class GlassStyles {
  GlassStyles._();

  static const double blurSigma = 16.0;
  static const double borderRadius = AppRadius.xl; // 22
  static const EdgeInsets cardPadding = EdgeInsets.all(18.0); // cardPadding.inner

  static double blurSigmaFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return 8.0;
    }
    return blurSigma;
  }

  static LinearGradient backgroundGradientFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF9FBFF),
          Color(0xFFF0F5FC),
          Color(0xFFEAF1FB),
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
    );
  }

  static LinearGradient glassGradientFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xF7FFFFFF),
          Color(0xE7F2FAFF),
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      // Neutral dark glass matches RN surfaceSoft = rgba(255, 255, 255, 0.04)
      colors: [
        Color(0x0CFFFFFF), // ~5%
        Color(0x07FFFFFF), // ~3%
      ],
    );
  }

  static LinearGradient accentGlassGradientFor(
    Brightness brightness,
    Color accent,
  ) {
    if (brightness == Brightness.light) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.2),
          const Color(0xF7FFFFFF),
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent.withValues(alpha: 0.24),
        const Color(0xC20E1622), // dark neutral base for accent cards
      ],
    );
  }
}
