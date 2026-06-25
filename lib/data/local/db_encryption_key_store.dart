import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the SQLCipher database encryption key.
///
/// The key is a 256-bit (32-byte) random value generated once on first launch
/// and stored in [FlutterSecureStorage] (Android KeyStore / iOS Keychain).
/// The key never leaves the device and is never included in backups.
///
/// Usage:
/// ```dart
/// final key = await DbEncryptionKeyStore.loadOrGenerate();
/// // Pass key to NativeDatabase setup: db.execute("PRAGMA key = '$key'");
/// ```
abstract final class DbEncryptionKeyStore {
  static const _storageKey = 'beltech_db_encryption_key_v1';

  static final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Returns the persisted key, generating and storing a new one if absent.
  static Future<String> loadOrGenerate() async {
    var key = await _storage.read(key: _storageKey);
    if (key == null) {
      key = _generateKey();
      await _storage.write(key: _storageKey, value: key);
    }
    return key;
  }

  static String _generateKey() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    // Hex-encode for safe use in PRAGMA key = '...'
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
