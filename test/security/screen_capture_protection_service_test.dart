import 'package:beltech/core/security/screen_capture_protection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ScreenCaptureProtectionService.resetForTests);

  test('screenshot protection is currently disabled for all tabs', () {
    expect(ScreenCaptureProtectionService.shouldProtectTab(0), isFalse);
    expect(ScreenCaptureProtectionService.shouldProtectTab(1), isFalse);
    expect(ScreenCaptureProtectionService.shouldProtectTab(2), isFalse);
    expect(ScreenCaptureProtectionService.shouldProtectTab(3), isFalse);
    expect(ScreenCaptureProtectionService.shouldProtectTab(4), isFalse);
  });
}
