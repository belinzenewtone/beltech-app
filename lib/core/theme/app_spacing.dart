import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── Tokens ───────────────────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ── Layout ───────────────────────────────────────────────────────────────────
  static const double screenHorizontal =
      sm; // 8 (was 24) — Kotlin-parity tight margins
  static const double screenTop = 12; // 12 (was 16) — tighter top padding
  static const double shellHorizontal = sm; // 8 (was 16)
  static const double contentBottomSafe =
      20; // Consistent bottom padding across all screens
  static const double sectionBottom = 16; // reduced from 20
  static const double fabBottomOffset = 132; // RN fabBottom

  // ── Gaps ─────────────────────────────────────────────────────────────────────
  /// Between two sibling section blocks
  static const double sectionGap = 20; // RN sectionGap

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
