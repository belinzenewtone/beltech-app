import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentialsStore {
  SecureCredentialsStore(this._storage);

  static const String passwordHashKey = 'user_password_hash';
  static const String biometricEnabledKey = 'biometric_enabled';

  final FlutterSecureStorage _storage;

  Future<void> writePasswordHash(String hash) async {
    await _storage.write(key: passwordHashKey, value: hash);
  }

  Future<String?> readPasswordHash() async {
    return _storage.read(key: passwordHashKey);
  }

  Future<void> writeBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  Future<bool> readBiometricEnabled() async {
    final value = await _storage.read(key: biometricEnabledKey);
    return value == 'true';
  }
}
