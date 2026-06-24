import 'package:flutter/services.dart';

class NativeSmsReceiver {
  static const _channel = MethodChannel('beltech.app/sms');
  final void Function(Map<String, dynamic>) onSmsReceived;

  NativeSmsReceiver({required this.onSmsReceived}) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMpesaSmsReceived') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        onSmsReceived(args);
      }
    });
  }
}
