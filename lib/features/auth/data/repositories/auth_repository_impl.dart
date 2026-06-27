import 'package:beltech/core/security/secure_credentials_store.dart';
import 'package:beltech/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_auth/local_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._localAuth, this._credentialsStore);

  final LocalAuthentication _localAuth;
  final SecureCredentialsStore _credentialsStore;

  @override
  Future<bool> isBiometricSupported() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final deviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && deviceSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isBiometricEnabled() {
    return _credentialsStore.readBiometricEnabled();
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await _credentialsStore.writeBiometricEnabled(enabled);
  }

  @override
  Future<bool> authenticate() async {
    final enabled = await isBiometricEnabled();
    final supported = await isBiometricSupported();
    if (!enabled || !supported) {
      return false;
    }
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock secure actions',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isPinSet() async {
    final pin = await _credentialsStore.readPin();
    return pin != null && pin.isNotEmpty;
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final stored = await _credentialsStore.readPin();
    return stored == pin;
  }

  @override
  Future<void> setPin(String pin) async {
    await _credentialsStore.writePin(pin);
  }

  @override
  Future<void> clearPin() async {
    await _credentialsStore.deletePin();
  }
}
