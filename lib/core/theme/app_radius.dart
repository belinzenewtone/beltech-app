import 'package:flutter/material.dart';

/// Shared corner-radius tokens.
///
/// Use these constants everywhere instead of raw doubles so that
/// the visual language stays consistent in one pass.
///
/// Reference mapping (RN ↔ Flutter):
///   sm   (8)   — inline badges, tiny chips
///   md   (12)  — filter chips, small cards
///   lg   (16)  — buttons, inputs, snackbars
///   xl   (22)  — standard cards
///   xxl  (28)  — bottom-sheets, dialogs, hero cards
///   full       — pills, avatars
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double xxl = 28;
  static const double full = 9999;

  // ── Convenience BorderRadius objects ────────────────────────────────────────

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}
