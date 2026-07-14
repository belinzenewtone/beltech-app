import 'package:beltech/core/security/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hasher = PasswordHasher();

  test('hash format is salt_base64:hash_hex and verifies password', () {
    final hash = hasher.hash('secret-123');
    final parts = hash.split(':');

    expect(parts.length, 2);
    expect(parts[0].isNotEmpty, isTrue);
    expect(parts[1].length, 64);
    expect(hasher.verify('secret-123', hash), isTrue);
    expect(hasher.verify('wrong-password', hash), isFalse);
  });

  test('hash is not equal to plain text', () {
    final hash = hasher.hash('secret-123');
    expect(hash, isNot('secret-123'));
  });
}
