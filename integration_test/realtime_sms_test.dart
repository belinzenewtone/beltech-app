// Integration test for Phase 5 real-time SMS ingestion.
//
// Prerequisites:
//   - Physical Android device (WorkManager lifecycle not reliable on emulator).
//   - App installed with READ_SMS + RECEIVE_SMS permissions granted.
//   - ADB access to inject a test SMS.
//
// Run with:
//   flutter test integration_test/realtime_sms_test.dart \
//     --device-id <device-id>
//
// How it works:
//   1. The test sends an ADB broadcast that mimics an incoming SMS.
//   2. MpesaSmsReceiver fires → schedules WorkManager + calls MethodChannel.
//   3. The test waits up to 10 seconds for the transaction to appear in the
//      local DB via the ExpensesRepository watch stream.
//   4. A second identical SMS is injected; the test asserts no duplicate is
//      created (4-tier dedup from Phase 3 must block it).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // NOTE: These tests require device-specific setup and are skipped by default
  // in CI.  Remove the skip flag when running on a physical device.

  group('Real-time SMS ingestion (Phase 5)', () {
    testWidgets(
      'SMS received with app closed → transaction in ledger within 10 s',
      (tester) async {
        // TODO: inject via ADB:
        //   adb shell am broadcast -a android.provider.Telephony.SMS_RECEIVED \
        //     --es "pdus" "<base64-encoded-PDU>" \
        //     -p com.beltech.app
        //
        // Then verify ExpensesRepository.watchSnapshot() emits a row matching
        // testSmsBody within a 10-second timeout.
        //
        // Placeholder — replace with actual device-side injection logic.
        expect(true, isTrue, reason: 'Placeholder — implement with ADB helper');
      },
      skip: true,
    );

    testWidgets(
      'No duplicate when BroadcastReceiver + ContentProvider both deliver same SMS',
      (tester) async {
        // TODO:
        //   1. Inject testSmsBody via BroadcastReceiver (simulates real-time).
        //   2. Wait for transaction to appear (≤10 s).
        //   3. Call importFromDevice() to simulate ContentProvider backfill.
        //   4. Assert transaction count is still 1 (dedup blocked the duplicate).
        expect(true, isTrue, reason: 'Placeholder — implement with ADB helper');
      },
      skip: true,
    );

    testWidgets(
      'Multi-part SMS (160+ chars) assembled correctly',
      (tester) async {
        // TODO:
        //   Inject two PDU fragments that together form testSmsBody.
        //   Assert one transaction is created with the correct full amount.
        expect(true, isTrue, reason: 'Placeholder — implement PDU split helper');
      },
      skip: true,
    );
  });
}
