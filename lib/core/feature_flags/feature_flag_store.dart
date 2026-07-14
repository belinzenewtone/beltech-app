import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages feature flag state with optional per-user rollout percentages.
///
/// Rollout logic:
/// - Each flag has an independently stored `rolloutPercentage` (0–100).
///   - 100 = enabled for all users (default)
///   - 0   = kill-switch, disabled for everyone
///   - N   = enabled for approximately N % of users, determined by a
///           deterministic hash of the user ID so a given user always sees
///           the same state.
/// - Remote configuration can override both the enabled flag and the rollout
///   percentage via [applyRemoteValues].
class FeatureFlagStore {
  static const String _keyPrefix = 'feature_flag';
  static const String _rolloutPrefix = 'feature_flag_rollout';

  /// Returns `true` if the flag is enabled (no rollout check — use
  /// [isEnabledFor] when you have a user ID).
  Future<bool> isEnabled(FeatureFlag flag) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(flag)) ?? flag.defaultEnabled;
  }

  /// Returns `true` if the flag is enabled AND the given [userId] falls within
  /// the configured rollout percentage for this flag.
  ///
  /// If [userId] is null, falls back to [isEnabled].
  Future<bool> isEnabledFor(FeatureFlag flag, {String? userId}) async {
    if (!await isEnabled(flag)) return false;
    if (userId == null) return true;

    final pct = await rolloutPercentage(flag);
    if (pct >= 100) return true;
    if (pct <= 0) return false;

    return _stableRolloutBucket(userId: userId, flagKey: flag.key) < pct;
  }

  /// Returns the stored rollout percentage (0–100) for [flag].
  /// Defaults to 100 if not set.
  Future<int> rolloutPercentage(FeatureFlag flag) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_rolloutKey(flag)) ?? 100;
  }

  Future<Map<FeatureFlag, bool>> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <FeatureFlag, bool>{};
    for (final flag in FeatureFlag.values) {
      result[flag] = prefs.getBool(_key(flag)) ?? flag.defaultEnabled;
    }
    return result;
  }

  Future<void> setValue({
    required FeatureFlag flag,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(flag), enabled);
  }

  /// Persists a rollout percentage (0–100) for [flag].
  /// Setting to 0 acts as a kill-switch; 100 enables for all users.
  Future<void> setRolloutPercentage({
    required FeatureFlag flag,
    required int percentage,
  }) async {
    assert(percentage >= 0 && percentage <= 100);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_rolloutKey(flag), percentage.clamp(0, 100));
  }

  Future<void> applyRemoteValues(Map<String, bool> values) async {
    if (values.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in values.entries) {
      final flag = FeatureFlag.fromKey(entry.key);
      if (flag == null) continue;
      await prefs.setBool(_key(flag), entry.value);
    }
  }

  /// Applies remote rollout percentages received from the server.
  /// Keys are flag keys (e.g. `'background_sync'`); values are 0–100.
  Future<void> applyRemoteRollout(Map<String, int> rollout) async {
    if (rollout.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in rollout.entries) {
      final flag = FeatureFlag.fromKey(entry.key);
      if (flag == null) continue;
      await prefs.setInt(_rolloutKey(flag), entry.value.clamp(0, 100));
    }
  }

  String _key(FeatureFlag flag) => '$_keyPrefix.${flag.key}';
  String _rolloutKey(FeatureFlag flag) => '$_rolloutPrefix.${flag.key}';

  int _stableRolloutBucket({required String userId, required String flagKey}) {
    // FNV-1a 32-bit hash for deterministic cross-run bucketing.
    var hash = 0x811C9DC5;
    final key = '$userId|$flagKey';
    for (final codeUnit in key.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return (hash & 0x7FFFFFFF) % 100;
  }
}
