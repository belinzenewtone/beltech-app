import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MerchantLearningService {
  MerchantLearningService();

  static const String _prefsKey = 'merchant_category_rules_v1';
  Map<String, String>? _cache;

  Future<String> resolveCategory({
    required String merchantTitle,
    required String fallbackCategory,
  }) async {
    final rules = await _loadRules();
    final normalized = _normalizeMerchant(merchantTitle);
    final learned = rules[normalized];
    if (learned != null && learned.isNotEmpty) {
      return learned;
    }
    // Do NOT run inference here — the caller (e.g. _resolveLearnedCategoryImpl)
    // passes the actual transaction amount to CategoryInferenceEngine for
    // amount-aware heuristics. Running inference with amountKes: 0 here
    // would produce incorrect results and skip the caller's smarter logic.
    return fallbackCategory;
  }

  Future<void> learn({
    required String merchantTitle,
    required String category,
  }) async {
    final normalized = _normalizeMerchant(merchantTitle);
    if (normalized.isEmpty || category.trim().isEmpty) {
      return;
    }
    final rules = await _loadRules();
    rules[normalized] = category.trim();
    await _persistRules(rules);
  }

  Future<Map<String, String>> _loadRules() async {
    if (_cache != null) {
      return _cache!;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      _cache = <String, String>{};
      return _cache!;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      _cache = <String, String>{};
      return _cache!;
    }
    _cache = decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
    return _cache!;
  }

  Future<void> _persistRules(Map<String, String> rules) async {
    final prefs = await SharedPreferences.getInstance();
    _cache = Map<String, String>.from(rules);
    await prefs.setString(_prefsKey, jsonEncode(_cache));
  }

  String _normalizeMerchant(String merchantTitle) {
    return merchantTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
