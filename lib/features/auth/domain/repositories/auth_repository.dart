abstract class AuthRepository {
  Future<bool> isBiometricSupported();

  Future<bool> isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled);

  Future<bool> authenticate();
}
