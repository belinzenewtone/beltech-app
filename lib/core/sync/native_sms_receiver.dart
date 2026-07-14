import 'dart:async';

import 'package:beltech/core/sync/sms_receiver_channel.dart';

/// Legacy callback-based wrapper around [SmsReceiverChannel].
///
/// Kept for backwards compatibility with [SmsAutoImportService].  New code
/// should subscribe to [SmsReceiverChannel.instance.events] directly.
class NativeSmsReceiver {
  NativeSmsReceiver({required this.onSmsReceived}) {
    SmsReceiverChannel.instance.initialize();
    _sub = SmsReceiverChannel.instance.events.listen((event) {
      onSmsReceived({
        'body':      event.body,
        'sender':    event.sender,
        'timestamp': event.receivedAt.millisecondsSinceEpoch,
      });
    });
  }

  final void Function(Map<String, dynamic>) onSmsReceived;
  late final StreamSubscription<RawSmsEvent> _sub;

  void dispose() => _sub.cancel();
}
