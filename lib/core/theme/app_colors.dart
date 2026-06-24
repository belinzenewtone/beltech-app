import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Background ──────────────────────────────────────────────────────────────
  // RN palette: near-black with subtle cool tint (matches screenshots exactly)
  static const Color background = Color(0xFF0B0F14);
  static const Color backgroundTop = Color(0xFF0B0F14); // RN uses solid background mostly
  static const Color backgroundBottom = Color(0xFF0B0F14);

  // ── Surfaces ─────────────────────────────────────────────────────────────────
  // RN palette: dark neutral surfaces
  static const Color surface = Color(0xFF151B22);
  static const Color surfaceElevated = Color(0xFF1B2430);
  static const Color surfaceMuted = Color(0xFF202A35);
  static const Color surfaceAccent = Color(0xFF0E5E63);
  static const Color surfaceAccentStrong = Color(0xFF0F766E);
  static const Color surfaceAccentAlt = Color(0xFF113238);
  static const Color surfaceHeroInset = Color(0xFF1E2936);
  static const Color surfaceHeroControl = Color(0xFF223140);
  
  static const Color border = Color(0xFF31404F);
  static const Color borderStrong = Color(0xFF5B7086);
  static const Color borderSubtle = Color(0xFF22303D);
  static const Color surfaceSubtle = Color(0xFF1E262F);
  static const Color borderOnHero = Color(0x38A9B4C2); // rgba(169, 180, 194, 0.22)

  // ── Accent — TEAL (matches RN primary color throughout) ──────────────────────
  static const Color accent = Color(0xFF0F766E);
  static const Color accentStrong = Color(0xFF0B5D57); // accentDark
  static const Color accentSoft = Color(0x294FD1D9); // rgba(79, 209, 217, 0.16)
  static const Color accentLight = Color(0xFF4FD1D9);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);   // green-500
  static const Color warning = Color(0xFFF59E0B);   // amber-400
  static const Color danger  = Color(0xFFF87171);   // red-400
  static const Color info    = Color(0xFF60A5FA);   // blue-400
  static const Color orange  = Color(0xFFFB923C);   // orange-400
  
  static const Color surfaceWarm = Color(0x1EF59E0B); // rgba(245, 158, 11, 0.12)
  static const Color surfaceSuccess = Color(0x1E22C55E); // rgba(34, 197, 94, 0.12)
  static const Color surfaceSoft = Color(0x0AFFFFFF); // rgba(255, 255, 255, 0.04)

  // ── Semantic muted (swipe-action / status backgrounds) ───────────────────────
  static const Color successMuted = Color(0xFF14532D);
  static const Color dangerMuted  = Color(0xFF7F1D1D);
  static const Color warningMuted = Color(0xFF78350F);

  // ── Tooltip / chart overlay ───────────────────────────────────────────────────
  static const Color tooltipBackground = Color(0xB8020617); // overlay

  // ── Text (three levels) ──────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFA9B4C2);
  static const Color textMuted     = Color(0xFF7D8896);
  static const Color textOnHeroMuted = Color(0xFFD7E4EA);

  // ── Extended palette ─────────────────────────────────────────────────────────
  static const Color teal   = Color(0xFF0D9488); // teal-600 (secondary teal)
  static const Color violet = Color(0xFF8B5CF6); // violet-500
  static const Color slate  = Color(0xFF475569); // slate-600
  static const Color azure  = Color(0xFF3B82F6); // blue-500
  static const Color sky    = Color(0xFF0EA5E9); // sky-500

  // ── Glow colors (radial background atmosphere) ───────────────────────────────
  static const Color glowBlue   = Color(0x3860A5FA); // rgba(96, 165, 250, 0.22)
  static const Color glowTeal   = Color(0x2E4FD1D9); // rgba(79, 209, 217, 0.18)
  static const Color glowIndigo = Color(0x298B6DFF); // rgba(139, 109, 255, 0.16)
  static const Color glowViolet = glowIndigo; // alias
  static const Color glowAmber  = Color(0x29F59E0B); // amberSoft 16%

  // ── Category colors (foreground) — matching RN colored pill borders ───────────
  static const Color categoryWork      = Color(0xFF4F8CFF); // RN categoryColors.work
  static const Color categoryGrowth    = Color(0xFF8B6DFF); // RN categoryColors.growth
  static const Color categoryPersonal  = Color(0xFF2DCF91); // RN categoryColors.personal
  static const Color categoryBill      = Color(0xFFF39A4D); // RN categoryColors.bill
  static const Color categoryHealth    = danger;
  static const Color categoryOther     = textMuted;
  static const Color categoryFood      = orange;
  static const Color categoryAirtime   = Color(0xFFA855F7);
  static const Color categoryTransport = Color(0xFF06B6D4);


  // ── Category muted backgrounds (for chips/avatars) ───────────────────────────
  static const Color categoryFoodBg      = Color(0xFF431407);
  static const Color categoryAirtimeBg   = Color(0xFF3B0764);
  static const Color categoryBillBg      = Color(0xFF451A03);
  static const Color categoryTransportBg = Color(0xFF083344);

  /// Returns the foreground color for a named category (case-insensitive).
  static Color categoryColorFor(String category) {
    return switch (category.toLowerCase()) {
      'work' => categoryWork,
      'growth' || 'personal growth' => categoryGrowth,
      'personal' => categoryPersonal,
      'bill' || 'bills' || 'utilities' => categoryBill,
      'health' || 'medical' || 'healthcare' => categoryHealth,
      'food' || 'restaurant' || 'groceries' || 'eating out' || 'food & dining' => categoryFood,
      'airtime' || 'mobile' || 'data' => categoryAirtime,
      'transport' || 'transit' || 'fuel' => categoryTransport,
      'shopping' => const Color(0xFFEC4899),   // pink-500
      'rent' => const Color(0xFFEF4444),       // red-500
      'savings' => accent,                     // teal
      'loans' || 'loans & credit' || 'credit' => const Color(0xFFDC2626), // red-600
      'transfer' => const Color(0xFF6366F1),   // indigo-500
      'education' => sky,                      // sky-500  #0ea5e9
      'entertainment' => warning,              // amber-400 #f59e0b
      'family' => const Color(0xFFA855F7),     // purple-500
      'household groceries' => const Color(0xFF84CC16), // lime-400
      // Income categories
      'salary' || 'payroll' => success,
      'freelance' || 'contract' => azure,
      'business' || 'revenue' => orange,
      'm-pesa received' || 'received' => success,
      'investment' || 'dividends' => violet,
      'other income' => categoryOther,
      // Transfer / movement
      'cash withdrawal' || 'atm' => orange,
      _ => categoryOther,
    };
  }

  // ── Brightness-aware helpers ─────────────────────────────────────────────────
  static Color backgroundFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFF2F6FC) : background;

  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFFFFFFF) : surface;

  static Color surfaceMutedFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFF1F5FB) : surfaceMuted;

  static Color surfaceSubtleFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFEBF1FA) : surfaceSubtle;

  static Color borderFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFCBD5E1) : border;

  static Color borderStrongFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF94A3B8) : borderStrong;

  static Color textPrimaryFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF0F172A) : textPrimary;

  static Color textSecondaryFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF475569) : textSecondary;

  static Color textMutedFor(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF94A3B8) : textMuted;
}
