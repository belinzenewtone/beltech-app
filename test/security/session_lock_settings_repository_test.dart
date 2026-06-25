import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads the default grace period when unset', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SessionLockSettingsRepository();

    final settings = await repository.read();

    expect(settings.gracePeriodSeconds, 15);
  });

  test('persists a supported grace period', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SessionLockSettingsRepository();

    await repository.setGracePeriodSeconds(60);
    final settings = await repository.read();

    expect(settings.gracePeriodSeconds, 60);
  });
}
