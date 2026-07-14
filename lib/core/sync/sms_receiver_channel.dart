import 'dart:async';

import 'package:flutter/services.dart';

/// A raw M-Pesa SMS event delivered by the native BroadcastReceiver.
class RawSmsEvent {
  const RawSmsEvent({
    required this.body,
    required this.sender,
    required this.receivedAt,
  });

  /// Full concatenated SMS body (multi-part PDUs already assembled on native side).
  final String body;

  /// Originating address (e.g. "MPESA", "SAFARICOM", or a shortcode).
  final String sender;

  /// Carrier-reported delivery timestamp (from the first PDU).
  final DateTime receivedAt;
}

/// Dart client for the native `MpesaSmsReceiver` MethodChannel.
///
/// Exposes a broadcast [Stream<RawSmsEvent>] so that multiple listeners can
/// react to real-time incoming M-Pesa SMS without setting up their own
/// MethodChannel handlers (only one handler per channel is allowed).
///
/// Usage:
/// ```dart
/// SmsReceiverChannel.instance.initialize();
/// SmsReceiverChannel.instance.events.listen((event) { ... });
/// ```
///
/// Call [initialize] once during app startup (e.g. in a service's `start()`).
/// The channel is a singleton; subsequent calls to [initialize] are no-ops.
class SmsReceiverChannel {
  SmsReceiverChannel._();

  static final SmsReceiverChannel instance = SmsReceiverChannel._();

  // Channel name must match MainActivity.kt and MpesaSmsReceiver.kt.
  static const _channel = MethodChannel('beltech.app/sms');

  final StreamController<RawSmsEvent> _ctrl =
      StreamController<RawSmsEvent>.broadcast();

  /// Real-time stream of incoming M-Pesa SMS events.
  Stream<RawSmsEvent> get events => _ctrl.stream;

  bool _initialized = false;

  /// Register the MethodChannel handler.  Safe to call multiple times.
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onMpesaSmsReceived') return;
    final args = Map<String, dynamic>.from(call.arguments as Map);
    final body   = ((args['body']   as String?) ?? '').trim();
    final sender = ((args['sender'] as String?) ?? '').trim();
    final tsMs   = (args['timestamp'] as int?) ??
        DateTime.now().millisecondsSinceEpoch;
    if (body.isEmpty) return;
    _ctrl.add(RawSmsEvent(
      body:       body,
      sender:     sender,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(tsMs),
    ));
  }

  /// Dismiss the "Processing M-Pesa SMS…" foreground notification that
  /// [MpesaSmsReceiver] posts when scheduling the WorkManager ingest task.
  /// Call after the ingest pipeline finishes draining.
  static Future<void> dismissIngestNotification() async {
    try {
      await _channel.invokeMethod<void>('dismissIngestNotification');
    } catch (_) {
      // No-op when running outside Android or notification already dismissed.
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _ctrl.close();
  }
}
