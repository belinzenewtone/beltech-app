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
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
