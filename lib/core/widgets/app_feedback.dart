import 'package:beltech/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralised user feedback helper.
///
/// Prefer [AppFeedback.success/error/info/warning] which route through the
/// Riverpod toast queue. The legacy snackbar path is kept as fallback when a
/// WidgetRef is not available.
class AppFeedback {
  const AppFeedback._();

  // ── Toast (preferred) ────────────────────────────────────────────────────────

  static void success(BuildContext context, String message, {WidgetRef? ref}) {
    if (ref != null) {
      ref.read(toastProvider.notifier).success(message);
    } else {
      _snackbar(context, message);
    }
  }

  static void error(BuildContext context, String message, {WidgetRef? ref}) {
    if (ref != null) {
      ref.read(toastProvider.notifier).error(message);
    } else {
      _snackbar(context, message);
    }
  }

  static void info(BuildContext context, String message, {WidgetRef? ref}) {
    if (ref != null) {
      ref.read(toastProvider.notifier).info(message);
    } else {
      _snackbar(context, message);
    }
  }

  static void warning(BuildContext context, String message, {WidgetRef? ref}) {
    if (ref != null) {
      ref.read(toastProvider.notifier).warning(message);
    } else {
      _snackbar(context, message);
    }
  }

  // ── Snackbar fallback ────────────────────────────────────────────────────────

  static void _snackbar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null || message.trim().isEmpty) return;
    messenger.hideCurrentSnackBar();
    final keyboardInset = MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message.trim(), maxLines: 3, overflow: TextOverflow.ellipsis),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 88 + keyboardInset),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
