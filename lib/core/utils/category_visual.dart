import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Shared visual descriptor for a spending category.
///
/// Used in transaction rows, expense snapshot cards, and analytics breakdowns
/// so that icon, foreground colour, and background colour are always consistent
/// across the whole app.
///
/// Category names match the RN EXPENSE_CATEGORIES / INCOME_CATEGORIES lists and
/// the CATEGORY_COLORS map in finance.constants.ts exactly.
({IconData icon, Color foreground, Color background}) categoryVisual(
  String category,
) {
  final n = category.trim().toLowerCase();

  // ── Expense categories ────────────────────────────────────────────────────
  if (n == 'food & dining' || n == 'eating out' || n == 'food') {
    return (
      icon: Icons.restaurant_outlined,
      foreground: AppColors.categoryFood,         // orange-400
      background: AppColors.categoryFoodBg,
    );
  }
  if (n == 'groceries') {
    return (
      icon: Icons.local_grocery_store_outlined,
      foreground: const Color(0xFF84CC16),         // lime-400 — matches RN
      background: const Color(0xFF1A2E05),
    );
  }
  if (n == 'airtime' || n.contains('airtime') || n.contains('mobile data')) {
    return (
      icon: Icons.phone_android_outlined,
      foreground: AppColors.categoryAirtime,
      background: AppColors.categoryAirtimeBg,
    );
  }
  if (n == 'utilities' || n == 'bills' || n.contains('bill')) {
    return (
      icon: Icons.receipt_long_outlined,
      foreground: AppColors.categoryBill,
      background: AppColors.categoryBillBg,
    );
  }
  if (n == 'transport' || n.contains('transport') ||
      n.contains('taxi') || n.contains('uber') || n.contains('matatu')) {
    return (
      icon: Icons.directions_bus_outlined,
      foreground: AppColors.categoryTransport,    // sky-500
      background: AppColors.categoryTransportBg,
    );
  }
  if (n == 'healthcare' || n.contains('health') || n.contains('medical')) {
    return (
      icon: Icons.local_hospital_outlined,
      foreground: AppColors.success,              // green-500  #22c55e
      background: AppColors.success.withValues(alpha: 0.18),
    );
  }
  if (n == 'shopping' || n.contains('clothes') || n.contains('fashion')) {
    return (
      icon: Icons.shopping_bag_outlined,
      foreground: const Color(0xFFEC4899),         // pink-500 — matches RN
      background: const Color(0xFF500724),
    );
  }
  if (n == 'entertainment' || n.contains('entertain') || n.contains('leisure')) {
    return (
      icon: Icons.movie_outlined,
      foreground: AppColors.warning,               // amber/orange — matches RN
      background: AppColors.warning.withValues(alpha: 0.18),
    );
  }
  if (n == 'education' || n.contains('educat') || n.contains('school') || n.contains('tuition')) {
    return (
      icon: Icons.school_outlined,
      foreground: AppColors.sky,                   // sky-500 — matches RN #06b6d4
      background: AppColors.sky.withValues(alpha: 0.18),
    );
  }
  if (n == 'savings' || n.contains('saving')) {
    return (
      icon: Icons.savings_outlined,
      foreground: AppColors.accent,                // teal-500 — matches RN
      background: AppColors.accent.withValues(alpha: 0.18),
    );
  }
  if (n == 'loans' || n == 'loans & credit' || n.contains('loan') ||
      n.contains('credit') || n.contains('fuliza') || n.contains('m-shwari')) {
    return (
      icon: Icons.account_balance_outlined,
      foreground: const Color(0xFFDC2626),          // red-600 — matches RN
      background: const Color(0xFF450A0A),
    );
  }
  if (n == 'rent' || n.contains('rent') || n.contains('housing')) {
    return (
      icon: Icons.home_outlined,
      foreground: const Color(0xFFEF4444),          // red-500 — matches RN
      background: const Color(0xFF450A0A),
    );
  }
  if (n == 'family' || n.contains('family') || n.contains('kids')) {
    return (
      icon: Icons.people_outline,
      foreground: AppColors.violet,                 // violet-500 — matches RN ~#a855f7
      background: AppColors.violet.withValues(alpha: 0.18),
    );
  }

  // ── Income categories ─────────────────────────────────────────────────────
  if (n == 'salary' || n.contains('salary') || n.contains('payroll')) {
    return (
      icon: Icons.payments_outlined,
      foreground: AppColors.success,
      background: AppColors.success.withValues(alpha: 0.18),
    );
  }
  if (n == 'freelance' || n.contains('freelance') || n.contains('contract')) {
    return (
      icon: Icons.work_outline_rounded,
      foreground: AppColors.azure,                  // blue-500
      background: AppColors.azure.withValues(alpha: 0.18),
    );
  }
  if (n == 'business' || n.contains('business') || n.contains('revenue')) {
    return (
      icon: Icons.storefront_outlined,
      foreground: AppColors.categoryFood,           // amber/orange
      background: AppColors.categoryFood.withValues(alpha: 0.18),
    );
  }
  if (n == 'm-pesa received' || n.contains('received') || n.contains('you have received')) {
    return (
      icon: Icons.arrow_downward_rounded,
      foreground: AppColors.success,
      background: AppColors.success.withValues(alpha: 0.18),
    );
  }
  if (n == 'investment' || n.contains('invest') || n.contains('dividend')) {
    return (
      icon: Icons.trending_up_rounded,
      foreground: AppColors.violet,
      background: AppColors.violet.withValues(alpha: 0.18),
    );
  }
  if (n == 'other income') {
    return (
      icon: Icons.add_circle_outline,
      foreground: AppColors.textSecondary,
      background: AppColors.accentSoft.withValues(alpha: 0.3),
    );
  }

  // ── Transfer / movement ───────────────────────────────────────────────────
  if (n == 'transfer' || n.contains('transfer') || n.contains('send money') ||
      n.contains('sent to') || n.contains('transferred')) {
    return (
      icon: Icons.swap_horiz_rounded,
      foreground: const Color(0xFF6366F1),          // indigo-500 — matches RN
      background: const Color(0xFF1E1B4B),
    );
  }
  if (n.contains('withdrawal') || n.contains('cash out') || n.contains('atm')) {
    return (
      icon: Icons.atm_outlined,
      foreground: AppColors.orange,
      background: AppColors.orange.withValues(alpha: 0.18),
    );
  }

  // ── Paybill / goods ───────────────────────────────────────────────────────
  if (n.contains('paybill') || n.contains('pay bill')) {
    return (
      icon: Icons.receipt_long_outlined,
      foreground: AppColors.categoryBill,
      background: AppColors.categoryBillBg,
    );
  }
  if (n.contains('buy goods') || n.contains('buygoods') || n.contains(' till ')) {
    return (
      icon: Icons.shopping_bag_outlined,
      foreground: AppColors.teal,
      background: AppColors.teal.withValues(alpha: 0.18),
    );
  }

  // ── Fallback ──────────────────────────────────────────────────────────────
  return (
    icon: Icons.payments_outlined,
    foreground: AppColors.textSecondary,
    background: AppColors.accentSoft.withValues(alpha: 0.3),
  );
}
