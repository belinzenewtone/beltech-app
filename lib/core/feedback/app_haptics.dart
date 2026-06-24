import 'package:flutter/services.dart';

/// Centralised haptic vocabulary for the whole app.
///
/// All methods are no-ops when haptics are disabled (e.g. via feature flag
/// or platform preference). Callers never need to guard individual calls.
///
/// Vocabulary:
/// - [lightImpact]  — nav taps, chip selections, minor actions
/// - [mediumImpact] — swipe threshold crossed, drag confirm
/// - [heavyImpact]  — hard confirmations, destructive locks
/// - [success]      — task complete, import succeeded, optimistic write confirmed
/// - [warning]      — budget limit reached, near-threshold alert
/// - [error]        — delete confirmed, irreversible action, import failed
/// - [selection]    — picker scroll tick, radio/checkbox toggle
class AppHaptics {
  const AppHaptics._();

  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  // ── Core impacts ──────────────────────────────────────────────────────────

  static Future<void> lightImpact() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyImpact() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  // ── Semantic events ───────────────────────────────────────────────────────

  /// Use when an action completes successfully (task done, import ok, etc.)
  static Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Use when approaching a limit or a warning state (budget, deadline, etc.)
  static Future<void> warning() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Use when a destructive or irreversible action is confirmed.
  static Future<void> error() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Use for picker scroll ticks, radio/checkbox toggles, segment changes.
  static Future<void> selection() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }
}
