import 'package:beltech/core/security/biometric_relock_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires relock when grace period has elapsed', () {
    final pausedAt = DateTime(2026, 3, 21, 10, 0, 0);

    final shouldRelock = BiometricRelockPolicy.shouldRelock(
      relockEnabled: true,
      unlockInProgress: false,
      pausedAt: pausedAt,
      now: pausedAt.add(const Duration(seconds: 30)),
      gracePeriod: const Duration(seconds: 15),
    );

    expect(shouldRelock, isTrue);
  });

  test('skips relock while still inside grace period', () {
    final pausedAt = DateTime(2026, 3, 21, 10, 0, 0);

    final shouldRelock = BiometricRelockPolicy.shouldRelock(
      relockEnabled: true,
      unlockInProgress: false,
      pausedAt: pausedAt,
      now: pausedAt.add(const Duration(seconds: 10)),
      gracePeriod: const Duration(seconds: 15),
    );

    expect(shouldRelock, isFalse);
  });

  test('skips relock when disabled or unlock is already in progress', () {
    final pausedAt = DateTime(2026, 3, 21, 10, 0, 0);

    expect(
      BiometricRelockPolicy.shouldRelock(
        relockEnabled: false,
        unlockInProgress: false,
        pausedAt: pausedAt,
        now: pausedAt.add(const Duration(minutes: 2)),
        gracePeriod: Duration.zero,
      ),
      isFalse,
    );
    expect(
      BiometricRelockPolicy.shouldRelock(
        relockEnabled: true,
        unlockInProgress: true,
        pausedAt: pausedAt,
        now: pausedAt.add(const Duration(minutes: 2)),
        gracePeriod: Duration.zero,
      ),
      isFalse,
    );
  });
}
