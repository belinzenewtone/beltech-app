import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class ScreenCaptureProtectionService {
  const ScreenCaptureProtectionService._();

  static bool? _isSecureEnabled;

  /// Finance (1) and Profile (4) are treated as sensitive tabs.
  static bool shouldProtectTab(int tabIndex) => tabIndex == 1 || tabIndex == 4;

  static Future<void> syncForTab(int tabIndex) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final shouldEnableSecure = shouldProtectTab(tabIndex);
    if (_isSecureEnabled == shouldEnableSecure) {
      return;
    }

    try {
      if (shouldEnableSecure) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
      _isSecureEnabled = shouldEnableSecure;
    } catch (_) {
      // Keep app flow resilient if platform channels are unavailable.
    }
  }

  @visibleForTesting
  static void resetForTests() => _isSecureEnabled = null;
}
