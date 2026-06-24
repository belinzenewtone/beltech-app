import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hashes passwords with HMAC-SHA256 using a random per-password salt.
///
/// Stored format: "<salt_base64>:<hash_hex>" — 16 bytes salt + 32 bytes HMAC.
/// This prevents rainbow-table attacks and ensures identical passwords
/// produce different hashes.
class PasswordHasher {
  /// Pepper is a static application secret mixed into every hash.
  /// In production this should be loaded from secure configuration.
  static const String _pepper = 'beltech_v2_auth_pepper_2026';

  String hash(String password) {
    final salt = _generateSalt();
    final hash = _hmac(password, salt);
    return '${base64Encode(salt)}:${hash}';
  }

  bool verify(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = base64Decode(parts[0]);
    final expected = parts[1];
    return _hmac(password, salt) == expected;
  }

  String _hmac(String password, List<int> salt) {
    final key = utf8.encode(_pepper);
    final message = [...salt, ...utf8.encode(password)];
    final hmac = Hmac(sha256, key);
    return hmac.convert(message).toString();
  }

  List<int> _generateSalt() {
    final rng = Random.secure();
    return List<int>.generate(16, (_) => rng.nextInt(256));
  }
}
