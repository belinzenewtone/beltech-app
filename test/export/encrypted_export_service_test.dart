import 'package:beltech/features/export/data/services/encrypted_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = EncryptedExportService();

  group('EncryptedExportService', () {
    test('encrypt produces non-empty output different from plaintext', () {
      const plain = 'id,title,amount\n1,Food,500';
      final encrypted = service.encrypt(
        plainText: plain,
        password: 'secret123',
      );
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(plain));
    });

    test('decrypt with correct password returns original plaintext', () {
      const plain = 'id,title,amount\n1,Food,500\n2,Transport,300';
      final encrypted = service.encrypt(
        plainText: plain,
        password: 'my_password',
      );
      final decrypted = service.decrypt(
        base64Payload: encrypted,
        password: 'my_password',
      );
      expect(decrypted, plain);
    });

    test('decrypt with wrong password throws', () {
      const plain = 'sensitive data';
      final encrypted = service.encrypt(plainText: plain, password: 'correct');
      expect(
        () => service.decrypt(base64Payload: encrypted, password: 'wrong'),
        throwsException,
      );
    });

    test('encrypting same plaintext twice produces different ciphertexts', () {
      const plain = 'test';
      final enc1 = service.encrypt(plainText: plain, password: 'pw');
      final enc2 = service.encrypt(plainText: plain, password: 'pw');
      expect(enc1, isNot(enc2));
    });

    test('handles empty plaintext', () {
      final encrypted = service.encrypt(plainText: '', password: 'pw');
      final decrypted = service.decrypt(
        base64Payload: encrypted,
        password: 'pw',
      );
      expect(decrypted, '');
    });

    test('handles large plaintext', () {
      final plain = List.generate(
        100,
        (i) => 'row $i, data, ${i * 10}',
      ).join('\n');
      final encrypted = service.encrypt(
        plainText: plain,
        password: 'secure_pass',
      );
      final decrypted = service.decrypt(
        base64Payload: encrypted,
        password: 'secure_pass',
      );
      expect(decrypted, plain);
    });
  });
}
