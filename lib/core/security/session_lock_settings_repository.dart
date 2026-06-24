import 'package:shared_preferences/shared_preferences.dart';

class SessionLockSettings {
  const SessionLockSettings({
    required this.gracePeriodSeconds,
  });

  final int gracePeriodSeconds;

  Duration get gracePeriod => Duration(seconds: gracePeriodSeconds);
}

class SessionLockSettingsRepository {
  static const String _gracePeriodKey = 'security.session_lock_grace_seconds';
  static const int _defaultGracePeriodSeconds = 15;
  static const List<int> supportedGracePeriods = [0, 15, 30, 60, 300];

  Future<SessionLockSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_gracePeriodKey) ?? _defaultGracePeriodSeconds;
    final value =
        supportedGracePeriods.contains(raw) ? raw : _defaultGracePeriodSeconds;
    return SessionLockSettings(gracePeriodSeconds: value);
  }

  Future<void> setGracePeriodSeconds(int seconds) async {
    if (!supportedGracePeriods.contains(seconds)) {
      throw ArgumentError.value(seconds, 'seconds', 'Unsupported grace period');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gracePeriodKey, seconds);
  }
}
