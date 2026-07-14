import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RevampTelemetryService {
  static const String _eventsKey = 'revamp.telemetry_events';
  static const int _maxEvents = 100;
  static final RegExp _safeToken = RegExp(r'^[a-z0-9_.-]{1,32}$');

  Future<void> track(
    String eventName, {
    Map<String, Object?> attributes = const {},
  }) async {
    if (!_safeToken.hasMatch(eventName)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_eventsKey) ?? <String>[];
    final record = jsonEncode({
      'event': eventName,
      'ts': DateTime.now().toUtc().toIso8601String(),
      'attributes': _sanitizeAttributes(attributes),
    });
    current.add(record);
    final trimmed = current.length <= _maxEvents
        ? current
        : current.sublist(current.length - _maxEvents);
    await prefs.setStringList(_eventsKey, trimmed);
  }

  Future<List<Map<String, dynamic>>> readEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getStringList(_eventsKey) ?? const <String>[];
    return rows
        .map((row) => jsonDecode(row) as Map<String, dynamic>)
        .toList(growable: false);
  }

  Map<String, Object?> _sanitizeAttributes(Map<String, Object?> attributes) {
    final sanitized = <String, Object?>{};
    for (final entry in attributes.entries) {
      if (!_safeToken.hasMatch(entry.key)) {
        continue;
      }
      final value = _sanitizeValue(entry.value);
      if (value != null) {
        sanitized[entry.key] = value;
      }
    }
    return sanitized;
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null || value is bool || value is int || value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String && _safeToken.hasMatch(value)) {
      return value;
    }
    return null;
  }
}
