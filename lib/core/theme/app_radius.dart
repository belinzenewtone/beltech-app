import 'package:flutter/material.dart';

/// Shared corner-radius tokens.
///
/// Use these constants everywhere instead of raw doubles so that
/// the visual language stays consistent in one pass.
///
/// Crisp, Kotlin-parity corner scale. The reference app uses near-square
/// ~6dp corners on cards which is a large part of its tight, well-fitted
/// feel; large 16–28dp radii read as oversized/bubbly. Only true pills and
/// avatars use [full].
///
/// Mapping:
///   sm   (6)   — inline badges, tiny chips
///   md   (8)   — standard cards, small cards
///   lg   (10)  — buttons, inputs, snackbars
///   xl   (12)  — larger cards, panels
///   xxl  (16)  — bottom-sheets, dialogs, hero cards
///   full       — pills, avatars, floating nav
class AppRadius {
  AppRadius._();

  static const double sm = 6; // was 8
  static const double md = 8; // was 12
  static const double lg = 10; // was 16
  static const double xl = 12; // was 22
  static const double xxl = 16; // was 28
  static const double full = 9999;

  // ── Convenience BorderRadius objects ────────────────────────────────────────

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}
