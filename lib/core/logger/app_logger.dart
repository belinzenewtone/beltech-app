import 'dart:developer' as developer;

import 'package:sentry_flutter/sentry_flutter.dart';

/// Central structured logger for BELTECH.
///
/// Usage:
///   AppLogger.info('Sync started');
///   AppLogger.error('Sync failed', error: e, stackTrace: st);
///
/// In release builds (dart.vm.product = true), debug/info messages are
/// suppressed. Warnings and errors are always emitted.
///
/// `error(...)` calls are also forwarded to Sentry when a DSN is configured
/// (injected via `--dart-define=SENTRY_DSN=...` at build time). User identity
/// and financial data are never included — the `beforeSend` hook in main.dart
/// strips the user field from every event.
class AppLogger {
  AppLogger._();

  // True when compiled in release/AOT mode (no assert, no debug symbols).
  static const bool _isRelease =
      bool.fromEnvironment('dart.vm.product', defaultValue: false);

  static void debug(String message, {String? tag}) {
    if (_isRelease) return;
    _log('DEBUG', message, tag: tag);
  }

  static void info(String message, {String? tag}) {
    if (_isRelease) return;
    _log('INFO', message, tag: tag);
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log('WARN', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log(
      'ERROR',
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
    // Forward to Sentry for production crash visibility.
    // Only fires when a DSN is configured; no-ops otherwise.
    if (error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'logger_tag': tag ?? 'BELTECH', 'message': message}),
      );
    }
  }

  static void _log(
    String level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final name = tag ?? 'BELTECH';
    final body = error != null ? '$message\n↳ $error' : message;
    developer.log(
      '[$level] $body',
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
