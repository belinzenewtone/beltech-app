class BiometricRelockPolicy {
  const BiometricRelockPolicy._();

  static bool shouldRelock({
    required bool relockEnabled,
    required bool unlockInProgress,
    required DateTime? pausedAt,
    required DateTime now,
    required Duration gracePeriod,
  }) {
    if (!relockEnabled || unlockInProgress || pausedAt == null) {
      return false;
    }
    return now.difference(pausedAt) >= gracePeriod;
  }
}
