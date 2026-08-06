import 'package:flutter/material.dart';

/// Shared corner-radius tokens.
///
/// Use these constants everywhere instead of raw doubles so that
/// the visual language stays consistent in one pass.
///
/// Matches the React Native reference app token scale exactly:
///   sm   (8)   — inline badges, tiny chips, micro elements
///   md   (12)  — small elements, icon containers, tags
///   lg   (16)  — standard cards, buttons, inputs  ← AppCard default
///   xl   (20)  — hero/summary cards               ← FrostCard equivalent
///   xxl  (24)  — bottom-sheets, dialogs, modals
///   full       — pills, avatars, floating nav
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 9999;

  // ── Convenience BorderRadius objects ────────────────────────────────────────

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}
