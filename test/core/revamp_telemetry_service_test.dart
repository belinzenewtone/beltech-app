import 'package:beltech/core/telemetry/revamp_telemetry_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stores only privacy-safe telemetry attributes', () async {
    SharedPreferences.setMockInitialValues({});
    final service = RevampTelemetryService();

    await service.track(
      'weekly_review_notification_sent',
      attributes: {
        'scope': 'local',
        'tone': 'positive',
        'raw_message': 'RGH123 Confirmed. Ksh500.00',
        'amount': 2,
      },
    );

    final events = await service.readEvents();
    final attributes = events.single['attributes'] as Map<String, dynamic>;

    expect(attributes['scope'], 'local');
    expect(attributes['tone'], 'positive');
    expect(attributes['amount'], 2);
    expect(attributes.containsKey('raw_message'), isFalse);
  });
}
