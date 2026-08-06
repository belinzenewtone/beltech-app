import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── Tokens ───────────────────────────────────────────────────────────────────
  // Kotlin-parity scale: 4 / 8 / 12 / 16 / 24 / 32 / 48.
  // screenHorizontal = lg (16) matches Kotlin's 20dp hero margin closely and
  // prevents cards from spanning edge-to-edge, which was the main cause of the
  // layout feeling large/exaggerated.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12; // was 16 — Kotlin md
  static const double lg = 16; // was 24 — Kotlin lg
  static const double xl = 24; // was 32 — Kotlin xl
  static const double xxl = 32; // was 48 — Kotlin xxl
  static const double xxxl = 48; // was 64

  // ── Layout ───────────────────────────────────────────────────────────────────
  static const double screenHorizontal =
      md; // 12 — matches reference app spacing.screenHorizontal exactly
  static const double screenTop = 12; // 12 (was 16) — tighter top padding
  static const double shellHorizontal = lg; // 16 (was 8)
  static const double contentBottomSafe =
      20; // Consistent bottom padding across all screens
  static const double sectionBottom = 12; // reduced from 16
  static const double fabBottomOffset = 132; // RN fabBottom

  // ── Gaps ─────────────────────────────────────────────────────────────────────
  /// Between two sibling section blocks
  static const double sectionGap = 16; // was 20 — tighter section rhythm

  /// Between a section header and its first card
  static const double sectionHeaderGap = md; // RN headerGap

  /// Between adjacent cards in the same section
  static const double cardGap = md; // RN cardGap

  /// Between adjacent list items (tight)
  static const double listGap = sm; // RN listGap

  static EdgeInsets screenPadding(
    BuildContext context, {
    double bottom = contentBottomSafe,
  }) {
    return EdgeInsets.fromLTRB(
      screenHorizontal,
      screenTop,
      screenHorizontal,
      bottom + _safeBottomContribution(context),
    );
  }

  static EdgeInsets sectionPadding(
    BuildContext context, {
    double bottom = sectionBottom,
  }) {
    return EdgeInsets.fromLTRB(
      screenHorizontal,
      screenTop,
      screenHorizontal,
      bottom + _safeBottomContribution(context),
    );
  }

  static double fabBottom(BuildContext context) {
    return fabBottomOffset + _safeBottomContribution(context);
  }

  static double navBottom(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return math.max(safeBottom, md);
  }

  static double _safeBottomContribution(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom > 0 ? safeBottom * 0.6 : 0;
  }
}
