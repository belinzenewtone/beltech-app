part of 'app_shell.dart';

extension _AppShellBiometric on _AppShellState {
  Future<void> _initializeBiometricLock() async =>
      _refreshBiometricConfiguration(lockNow: true);
  Future<void> _applyBiometricLockOnResume() async {
    final pausedAt = _lastPausedAt;
    _lastPausedAt = null;
    final settings =
        await ref.read(sessionLockSettingsRepositoryProvider).read();
    if (!BiometricRelockPolicy.shouldRelock(
      relockEnabled: _biometricRelockEnabled,
      unlockInProgress: _biometricUnlockInProgress,
      pausedAt: pausedAt,
      now: DateTime.now(),
      gracePeriod: settings.gracePeriod,
    )) {
      return;
    }
    await _refreshBiometricConfiguration(lockNow: true);
  }
}
