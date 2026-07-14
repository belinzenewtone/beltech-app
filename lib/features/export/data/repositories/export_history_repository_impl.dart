import 'dart:convert';

import 'package:beltech/features/export/domain/entities/export_history_entry.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:beltech/features/export/domain/repositories/export_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExportHistoryRepositoryImpl implements ExportHistoryRepository {
  static const String _historyKey = 'export.history';
  static const int _maxEntries = 50;

  @override
  Future<List<ExportHistoryEntry>> readHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ExportHistoryEntry.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addResult(ExportResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await readHistory();
    history.insert(0, ExportHistoryEntry.fromResult(result));
    final trimmed = history.take(_maxEntries).toList();
    await prefs.setString(
      _historyKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
