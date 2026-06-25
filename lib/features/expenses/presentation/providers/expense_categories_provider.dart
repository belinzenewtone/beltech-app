import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const expenseCategoryDefaults = [
  'Food & Dining',
  'Airtime',
  'Transport',
  'Utilities',
  'Rent',
  'Shopping',
  'Healthcare',
  'Entertainment',
  'Education',
  'Savings',
  'Loans',
  'Family',
  'Other',
];

const _prefsKey = 'expense_categories_v1';

/// Registry of expense categories backed by SharedPreferences.
///
/// Consumers should treat the list as the source of truth for category
/// chips, breakdowns, and categorization quick-picks. The default list
/// matches the original hard-coded categories so existing installs keep
/// working.
final expenseCategoriesProvider =
    AsyncNotifierProvider<ExpenseCategoriesNotifier, List<String>>(
  ExpenseCategoriesNotifier.new,
);

class ExpenseCategoriesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return List.unmodifiable(expenseCategoryDefaults);
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded.whereType<String>().toList();
      return list.isEmpty ? List.unmodifiable(expenseCategoryDefaults) : list;
    } catch (_) {
      return List.unmodifiable(expenseCategoryDefaults);
    }
  }

  Future<void> addCategory(String name) async {
    name = name.trim();
    if (name.isEmpty) return;
    final current = await future;
    if (current.any((c) => c.toLowerCase() == name.toLowerCase())) return;
    await _persist([...current, name]);
  }

  Future<void> renameCategory(String oldName, String newName) async {
    newName = newName.trim();
    if (newName.isEmpty || oldName == newName) return;
    final current = await future;
    final index = current.indexWhere(
      (c) => c.toLowerCase() == oldName.toLowerCase(),
    );
    if (index == -1) return;
    if (current.any(
      (c) =>
          c.toLowerCase() == newName.toLowerCase() &&
          c.toLowerCase() != oldName.toLowerCase(),
    )) {
      return;
    }
    final updated = [...current];
    updated[index] = newName;
    await _persist(updated);
  }

  Future<void> deleteCategory(String name) async {
    final current = await future;
    final updated = current.where((c) => c != name).toList();
    if (updated.length == current.length) return;
    await _persist(updated);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = await future;
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex >= current.length) {
      return;
    }
    final updated = [...current];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    await _persist(updated);
  }

  Future<void> _persist(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(categories));
    state = AsyncValue.data(List.unmodifiable(categories));
  }
}
