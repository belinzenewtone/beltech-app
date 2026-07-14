import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:beltech/core/theme/app_colors.dart';

/// Semantic text style helpers.
///
/// Use these instead of raw `Theme.of(context).textTheme.*` calls so that
/// intent is self-documenting and consistent across every screen.
///
/// Example:
/// ```dart
/// Text('Good Morning', style: AppTypography.pageTitle(context))
/// Text('YOUR DAY', style: AppTypography.eyebrow(context))
/// Text('KES 4,200', style: AppTypography.amountLg(context))
/// ```
class AppTypography {
  AppTypography._();

  // ── Font Sizes ──────────────────────────────────────────────────────────────
  static const double xs = 12;
  static const double sm = 13;
  static const double md = 15;
  static const double lg = 17;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // ── Page-level ───────────────────────────────────────────────────────────────

  /// 26px w600 — screen main title
  static TextStyle pageTitle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 32 / 26,
    color: AppColors.textPrimaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  /// Alias of [pageTitle] for callers that prefer the semantic name.
  static TextStyle screenTitle(BuildContext context) => pageTitle(context);

  /// 11px w600 uppercase + letter-spacing — label above a title
  static TextStyle eyebrow(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textSecondaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  // ── Section-level ────────────────────────────────────────────────────────────

  /// 17px w600 — section label
  static TextStyle sectionTitle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 24 / 17,
    color: AppColors.textPrimaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  // ── Card-level ───────────────────────────────────────────────────────────────

  /// 15px w600 — card heading
  static TextStyle cardTitle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 22 / 15,
    color: AppColors.textPrimaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  /// 20px w600 — section/card title (alias for sectionTitle)
  static TextStyle title(BuildContext context) => sectionTitle(context);

  /// 20px w600 — small headline
  static TextStyle headlineSm(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.textPrimaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  /// 24px w600 — medium headline
  static TextStyle headlineMd(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.textPrimaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  // ── Body ─────────────────────────────────────────────────────────────────────

  /// 15px w400 — default body copy
  static TextStyle bodyMd(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AppColors.textSecondaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  /// alias of bodyMd
  static TextStyle body(BuildContext context) => bodyMd(context);

  /// 13px w400 — small supporting text, metadata
  static TextStyle bodySm(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 20 / 13,
    color: AppColors.textMutedFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  // ── Numeric / financial ──────────────────────────────────────────────────────

  /// 22px w700 — inline amounts on cards
  static TextStyle amount(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    color: AppColors.textPrimaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  /// Alias of [amount] for dashboard / summary statistics.
  static TextStyle statNumber(BuildContext context) => amount(context);

  /// 30px w700 — hero amounts (balance, total)
  static TextStyle amountLg(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 36 / 30,
    color: AppColors.textPrimaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  // ── Meta / label ─────────────────────────────────────────────────────────

  /// 12px w400 — chart axis labels, timestamp chips, fine-print metadata
  ///
  /// Use this instead of inline `TextStyle(fontSize: 12)` calls.
  static TextStyle metaText(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    color: AppColors.textMutedFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  /// 12px w500 — small uppercase labels, form section headers
  static TextStyle label(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
    letterSpacing: 0.3,
    color: AppColors.textSecondaryFor(Theme.of(context).brightness),
    decoration: TextDecoration.none,
  );

  // ── Utility ──────────────────────────────────────────────────────────────────

  /// Copy a style and apply a specific color without losing the rest.
  static TextStyle withColor(TextStyle style, Color color) =>
      style.copyWith(color: color);

  /// Copy a style and reduce opacity (for disabled / muted states).
  static TextStyle muted(TextStyle style) =>
      style.copyWith(color: style.color?.withValues(alpha: 0.5));

  // ── Overflow helpers ─────────────────────────────────────────────────────────

  /// Every Text widget that displays dynamic data should use these constraints
  /// to prevent layout breakage on small screens or long translations.
  static TextOverflow get overflow => TextOverflow.ellipsis;
  static int get maxLinesSingle => 1;
  static int get maxLinesDouble => 2;
}
