import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static bool _stretchMotionEnabled = true;

  static void setStretchMotionEnabled(bool enabled) {
    _stretchMotionEnabled = enabled;
  }

  static bool reduceMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final mediaReduce = mediaQuery?.disableAnimations ?? false;
    final platformReduce = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    return !_stretchMotionEnabled || mediaReduce || platformReduce;
  }

  static Duration duration(
    BuildContext context, {
    required int normalMs,
    int reducedMs = 0,
  }) {
    return Duration(milliseconds: reduceMotion(context) ? reducedMs : normalMs);
  }

  static Duration dialog(BuildContext context) {
    return duration(context, normalMs: 170, reducedMs: 0);
  }

  static Duration content(BuildContext context) {
    return duration(context, normalMs: 180, reducedMs: 0);
  }

  static Duration swipe(BuildContext context) {
    return duration(context, normalMs: 170, reducedMs: 0);
  }

  static Duration resize(BuildContext context) {
    return duration(context, normalMs: 140, reducedMs: 0);
  }
}
