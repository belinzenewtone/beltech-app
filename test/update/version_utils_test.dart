import 'package:beltech/core/update/domain/version_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareVersions', () {
    test('returns 0 for equal versions', () {
      expect(compareVersions('1.2.3', '1.2.3'), 0);
    });

    test('returns positive when left is newer', () {
      expect(compareVersions('1.3.0', '1.2.9'), greaterThan(0));
    });

    test('returns negative when right is newer', () {
      expect(compareVersions('2.0.0', '2.1.0'), lessThan(0));
    });

    test('handles short and long semantic versions', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2.0.1', '1.2.0'), greaterThan(0));
    });
  });
}
