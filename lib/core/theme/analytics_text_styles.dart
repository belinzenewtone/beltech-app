import 'package:flutter/material.dart';

/// Documented type scale consumed by all analytics screens.
///
/// Used in Phase 3 typography audit. Every analytics widget should read
/// its text styles from here rather than constructing ad-hoc copies.
class AnalyticsTextStyles {
  AnalyticsTextStyles._();

  // ── Large display values ──────────────────────────────────────────────────
  static TextStyle summaryValue(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w800,
          );

  // ── Section headers ───────────────────────────────────────────────────────
  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w700,
          );

  // ── Card body ─────────────────────────────────────────────────────────────
  static TextStyle cardLabel(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
          );

  static TextStyle cardMeta(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          );

  // ── Pill / badge ──────────────────────────────────────────────────────────
  static TextStyle pill(BuildContext context, Color color) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 11,
          );

  // ── Chart labels ──────────────────────────────────────────────────────────
  static TextStyle chartTick(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          );

  // ── Insight body ──────────────────────────────────────────────────────────
  static TextStyle insightBody(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          );
}
