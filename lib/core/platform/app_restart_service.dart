import 'dart:io';

import 'package:flutter/services.dart';

class AppRestartService {
  AppRestartService._();

  static const MethodChannel _channel = MethodChannel('beltech/app_control');

  static Future<bool> restart() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final restarted = await _channel.invokeMethod<bool>('restartApp');
    return restarted ?? false;
  }
}
