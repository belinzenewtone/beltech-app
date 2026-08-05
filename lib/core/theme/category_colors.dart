import 'package:flutter/material.dart';

/// 16-category colour system with separate light and dark variants.
///
/// Consumed as a `ThemeExtension`:
/// ```dart
/// final cat = Theme.of(context).extension<CategoryColors>()!;
/// ```
class CategoryColors extends ThemeExtension<CategoryColors> {
  const CategoryColors({
    required this.food,
    required this.transport,
    required this.utilities,
    required this.groceries,
    required this.rent,
    required this.airtime,
    required this.entertainment,
    required this.health,
    required this.education,
    required this.shopping,
    required this.savings,
    required this.investment,
    required this.bills,
    required this.housing,
    required this.loans,
    required this.defaultCategory,
  });

  // ── Light-mode defaults (daytime accessible palette) ─────────────────────
  static const light = CategoryColors(
    // Warm food — amber range
    food: Color(0xFFD97706),
    // Transport — cyan
    transport: Color(0xFF0891B2),
    // Utilities — deep purple
    utilities: Color(0xFF7C3AED),
    // Groceries — lime
    groceries: Color(0xFF65A30D),
    // Rent — red
    rent: Color(0xFFDC2626),
    // Airtime — violet
    airtime: Color(0xFF9333EA),
    // Entertainment — pink
    entertainment: Color(0xFFDB2777),
    // Health — green
    health: Color(0xFF16A34A),
    // Education — indigo
    education: Color(0xFF4F46E5),
    // Shopping — fuchsia
    shopping: Color(0xFFC026D3),
    // Savings — emerald
    savings: Color(0xFF059669),
    // Investment — teal
    investment: Color(0xFF0D9488),
    // Bills — deep orange
    bills: Color(0xFFEA580C),
    // Housing — warm red
    housing: Color(0xFFB91C1C),
    // Loans — dark red
    loans: Color(0xFF991B1B),
    // Fallback — slate
    defaultCategory: Color(0xFF64748B),
  );

  // ── Dark-mode defaults (brighter, higher contrast) ───────────────────────
  static const dark = CategoryColors(
    food: Color(0xFFFBBF24),
    transport: Color(0xFF22D3EE),
    utilities: Color(0xFFA78BFA),
    groceries: Color(0xFFA3E635),
    rent: Color(0xFFF87171),
    airtime: Color(0xFFC084FC),
    entertainment: Color(0xFFF472B6),
    health: Color(0xFF4ADE80),
    education: Color(0xFF818CF8),
    shopping: Color(0xFFE879F9),
    savings: Color(0xFF34D399),
    investment: Color(0xFF2DD4BF),
    bills: Color(0xFFFB923C),
    housing: Color(0xFFFCA5A5),
    loans: Color(0xFFFCA5A5),
    defaultCategory: Color(0xFF94A3B8),
  );

  final Color food;
  final Color transport;
  final Color utilities;
  final Color groceries;
  final Color rent;
  final Color airtime;
  final Color entertainment;
  final Color health;
  final Color education;
  final Color shopping;
  final Color savings;
  final Color investment;
  final Color bills;
  final Color housing;
  final Color loans;
  final Color defaultCategory;

  /// Resolves a human-readable category name to its colour.
  Color colorFor(String category) {
    final n = category.trim().toLowerCase();
    if (n.contains('food') || n.contains('dining') || n.contains('eating')) return food;
    if (n.contains('transport') || n.contains('fuel') || n.contains('matatu')) return transport;
    if (n.contains('utilities') || n.contains('utility')) return utilities;
    if (n.contains('groceries') || n.contains('mama mboga') || n.contains('supermarket')) return groceries;
    if (n.contains('rent')) return rent;
    if (n.contains('airtime') || n.contains('data') || n.contains('mobile')) return airtime;
    if (n.contains('entertainment') || n.contains('leisure')) return entertainment;
    if (n.contains('health') || n.contains('medical') || n.contains('pharmacy')) return health;
    if (n.contains('education') || n.contains('school') || n.contains('tuition')) return education;
    if (n.contains('shopping') || n.contains('clothes') || n.contains('fashion')) return shopping;
    if (n.contains('savings')) return savings;
    if (n.contains('investment') || n.contains('stocks') || n.contains('dividend')) return investment;
    if (n.contains('bill') || n.contains('paybill')) return bills;
    if (n.contains('housing') || n.contains('mortgage')) return housing;
    if (n.contains('loan') || n.contains('fuliza') || n.contains('credit')) return loans;
    return defaultCategory;
  }

  @override
  CategoryColors copyWith({
    Color? food,
    Color? transport,
    Color? utilities,
    Color? groceries,
    Color? rent,
    Color? airtime,
    Color? entertainment,
    Color? health,
    Color? education,
    Color? shopping,
    Color? savings,
    Color? investment,
    Color? bills,
    Color? housing,
    Color? loans,
    Color? defaultCategory,
  }) {
    return CategoryColors(
      food: food ?? this.food,
      transport: transport ?? this.transport,
      utilities: utilities ?? this.utilities,
      groceries: groceries ?? this.groceries,
      rent: rent ?? this.rent,
      airtime: airtime ?? this.airtime,
      entertainment: entertainment ?? this.entertainment,
      health: health ?? this.health,
      education: education ?? this.education,
      shopping: shopping ?? this.shopping,
      savings: savings ?? this.savings,
      investment: investment ?? this.investment,
      bills: bills ?? this.bills,
      housing: housing ?? this.housing,
      loans: loans ?? this.loans,
      defaultCategory: defaultCategory ?? this.defaultCategory,
    );
  }

  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) {
    if (other is! CategoryColors) return this;
    return CategoryColors(
      food: Color.lerp(food, other.food, t)!,
      transport: Color.lerp(transport, other.transport, t)!,
      utilities: Color.lerp(utilities, other.utilities, t)!,
      groceries: Color.lerp(groceries, other.groceries, t)!,
      rent: Color.lerp(rent, other.rent, t)!,
      airtime: Color.lerp(airtime, other.airtime, t)!,
      entertainment: Color.lerp(entertainment, other.entertainment, t)!,
      health: Color.lerp(health, other.health, t)!,
      education: Color.lerp(education, other.education, t)!,
      shopping: Color.lerp(shopping, other.shopping, t)!,
      savings: Color.lerp(savings, other.savings, t)!,
      investment: Color.lerp(investment, other.investment, t)!,
      bills: Color.lerp(bills, other.bills, t)!,
      housing: Color.lerp(housing, other.housing, t)!,
      loans: Color.lerp(loans, other.loans, t)!,
      defaultCategory: Color.lerp(defaultCategory, other.defaultCategory, t)!,
    );
  }
}
