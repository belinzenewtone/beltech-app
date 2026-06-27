import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentialsStore {
  SecureCredentialsStore(this._storage);

  static const String passwordHashKey = 'user_password_hash';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String pinKey = 'user_pin';

  final FlutterSecureStorage _storage;

  Future<void> writePasswordHash(String hash) async {
    await _storage.write(key: passwordHashKey, value: hash);
  }

  Future<String?> readPasswordHash() async {
    return _storage.read(key: passwordHashKey);
  }

  Future<void> writeBiometricEnabled(bool enabled) async {
    await _storage.write(key: biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> readBiometricEnabled() async {
    final value = await _storage.read(key: biometricEnabledKey);
    return value == 'true';
  }

  Future<void> writePin(String pin) async {
    await _storage.write(key: pinKey, value: pin);
  }

  Future<String?> readPin() async {
    return _storage.read(key: pinKey);
  }

  Future<void> deletePin() async {
    await _storage.delete(key: pinKey);
  }
}
