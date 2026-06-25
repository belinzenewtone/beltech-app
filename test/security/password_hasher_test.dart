import 'package:beltech/core/security/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hasher = PasswordHasher();

  test('hash is deterministic for same input', () {
    final first = hasher.hash('secret-123');
    final second = hasher.hash('secret-123');

    expect(first, second);
  });

  test('hash is not equal to plain text', () {
    final hash = hasher.hash('secret-123');
    expect(hash, isNot('secret-123'));
    expect(hash.length, 64);
  });
}
