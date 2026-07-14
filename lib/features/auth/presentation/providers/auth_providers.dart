import 'dart:async';

import 'package:beltech/core/di/security_providers.dart';
import 'package:beltech/core/di/telemetry_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final supported = await repository.isBiometricSupported();
    final enabled = await repository.isBiometricEnabled();
    final pinEnabled = await repository.isPinEnabled();
    return AuthState(
      biometricSupported: supported,
      biometricEnabled: enabled,
      isAuthenticating: false,
      errorMessage: null,
      pinEnabled: pinEnabled,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final supported = await repository.isBiometricSupported();
      final enabled = await repository.isBiometricEnabled();
      final pinEnabled = await repository.isPinEnabled();
      return AuthState(
        biometricSupported: supported,
        biometricEnabled: enabled,
        isAuthenticating: false,
        errorMessage: null,
        pinEnabled: pinEnabled,
      );
    });
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final supported = await repository.isBiometricSupported();
      if (enabled && !supported) {
        throw Exception(
          'Biometric authentication is not supported on this device.',
        );
      }
      await repository.setBiometricEnabled(enabled);
      await ref
          .read(revampTelemetryServiceProvider)
          .track(
            'biometric_lock_setting_changed',
            attributes: {'enabled': enabled},
          );
      final pinEnabled = await repository.isPinEnabled();
      return AuthState(
        biometricSupported: supported,
        biometricEnabled: enabled,
        isAuthenticating: false,
        errorMessage: null,
        pinEnabled: pinEnabled,
      );
    });
  }

  Future<void> setPinEnabled(bool enabled) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.setPinEnabled(enabled);
      final supported = await repository.isBiometricSupported();
      final biometricEnabled = await repository.isBiometricEnabled();
      await ref
          .read(revampTelemetryServiceProvider)
          .track(
            'pin_lock_setting_changed',
            attributes: {'enabled': enabled},
          );
      return AuthState(
        biometricSupported: supported,
        biometricEnabled: biometricEnabled,
        isAuthenticating: false,
        errorMessage: null,
        pinEnabled: enabled,
      );
    });
  }

  Future<bool> authenticateNow() async {
    final current = state.value ?? AuthState.initial;
    state = AsyncData(
      current.copyWith(isAuthenticating: true, errorMessage: null),
    );
    final repository = ref.read(authRepositoryProvider);
    final authenticated = await repository.authenticate();
    await ref
        .read(revampTelemetryServiceProvider)
        .track(
          'biometric_auth_attempt',
          attributes: {'result': authenticated ? 'success' : 'failure'},
        );
    final latest = state.value ?? current;
    state = AsyncData(
      latest.copyWith(
        isAuthenticating: false,
        errorMessage: authenticated
            ? null
            : 'Authentication was not completed.',
      ),
    );
    return authenticated;
  }
}

final authProvider =
    AsyncNotifierProvider<AuthController, AuthState>(
      AuthController.new,
    );

final sessionLockSettingsProvider = FutureProvider<SessionLockSettings>(
  (ref) => ref.watch(sessionLockSettingsRepositoryProvider).read(),
);

class SessionLockSettingsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setGracePeriodSeconds(int seconds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(sessionLockSettingsRepositoryProvider)
          .setGracePeriodSeconds(seconds);
      await ref
          .read(revampTelemetryServiceProvider)
          .track(
            'session_relock_delay_changed',
            attributes: {'seconds': seconds},
          );
      ref.invalidate(sessionLockSettingsProvider);
    });
  }
}

final sessionLockSettingsControllerProvider =
    AsyncNotifierProvider<SessionLockSettingsController, void>(
      SessionLockSettingsController.new,
    );

class PinController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final pinSet = await repository.isPinSet();
      if (pinSet) {
        final valid = await repository.verifyPin(currentPin);
        if (!valid) {
          throw Exception('Current PIN is incorrect.');
        }
      }
      if (!RegExp(r'^\d{6}$').hasMatch(newPin)) {
        throw Exception('PIN must be exactly 6 digits.');
      }
      await repository.setPin(newPin);
      await ref
          .read(revampTelemetryServiceProvider)
          .track('pin_changed');
    });
  }

  Future<void> setPin(String pin) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
        throw Exception('PIN must be exactly 6 digits.');
      }
      final repository = ref.read(authRepositoryProvider);
      await repository.setPin(pin);
      await ref
          .read(revampTelemetryServiceProvider)
          .track('pin_set');
    });
  }

  Future<bool> verifyPin(String pin) async {
    final repository = ref.read(authRepositoryProvider);
    return repository.verifyPin(pin);
  }
}

final pinControllerProvider = AsyncNotifierProvider<PinController, void>(
  PinController.new,
);
