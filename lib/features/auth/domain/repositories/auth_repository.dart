abstract class AuthRepository {
  Future<bool> isBiometricSupported();

  Future<bool> isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled);

  Future<bool> authenticate();

  Future<bool> isPinSet();

  Future<bool> isPinEnabled();

  Future<void> setPinEnabled(bool enabled);

  Future<bool> verifyPin(String pin);

  Future<void> setPin(String pin);

  Future<void> clearPin();
}
