import 'dart:async';

import 'package:beltech/core/di/security_providers.dart';
import 'package:beltech/core/di/telemetry_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends AutoDisposeAsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final supported = await repository.isBiometricSupported();
    final enabled = await repository.isBiometricEnabled();
    return AuthState(
      biometricSupported: supported,
      biometricEnabled: enabled,
      isAuthenticating: false,
      errorMessage: null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final supported = await repository.isBiometricSupported();
      final enabled = await repository.isBiometricEnabled();
      return AuthState(
        biometricSupported: supported,
        biometricEnabled: enabled,
        isAuthenticating: false,
        errorMessage: null,
      );
    });
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final supported = await repository.isBiometricSupported();
      if (enabled && !supported) {
        throw Exception(
            'Biometric authentication is not supported on this device.');
      }
      await repository.setBiometricEnabled(enabled);
      await ref.read(revampTelemetryServiceProvider).track(
        'biometric_lock_setting_changed',
        attributes: {'enabled': enabled},
      );
      return AuthState(
        biometricSupported: supported,
        biometricEnabled: enabled,
        isAuthenticating: false,
        errorMessage: null,
      );
    });
  }

  Future<bool> authenticateNow() async {
    final current = state.valueOrNull ?? AuthState.initial;
    state =
        AsyncData(current.copyWith(isAuthenticating: true, errorMessage: null));
    final repository = ref.read(authRepositoryProvider);
    final authenticated = await repository.authenticate();
    await ref.read(revampTelemetryServiceProvider).track(
      'biometric_auth_attempt',
      attributes: {'result': authenticated ? 'success' : 'failure'},
    );
    final latest = state.valueOrNull ?? current;
    state = AsyncData(
      latest.copyWith(
        isAuthenticating: false,
        errorMessage:
            authenticated ? null : 'Authentication was not completed.',
      ),
    );
    return authenticated;
  }
}

final authProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final sessionLockSettingsProvider = FutureProvider<SessionLockSettings>(
  (ref) => ref.watch(sessionLockSettingsRepositoryProvider).read(),
);

class SessionLockSettingsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setGracePeriodSeconds(int seconds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(sessionLockSettingsRepositoryProvider)
          .setGracePeriodSeconds(seconds);
      await ref.read(revampTelemetryServiceProvider).track(
        'session_relock_delay_changed',
        attributes: {'seconds': seconds},
      );
      ref.invalidate(sessionLockSettingsProvider);
    });
  }
}

final sessionLockSettingsControllerProvider =
    AutoDisposeAsyncNotifierProvider<SessionLockSettingsController, void>(
  SessionLockSettingsController.new,
);
