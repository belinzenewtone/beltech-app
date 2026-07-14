import 'package:beltech/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralised user feedback helper.
///
/// All messages route through the top-positioned Riverpod toast queue so
/// notifications always appear at the top of the screen.
class AppFeedback {
  const AppFeedback._();

  static void success(BuildContext context, String message, {WidgetRef? ref}) {
    _showToast(context, ref, (notifier) => notifier.success(message));
  }

  static void error(BuildContext context, String message, {WidgetRef? ref}) {
    _showToast(context, ref, (notifier) => notifier.error(message));
  }

  static void info(BuildContext context, String message, {WidgetRef? ref}) {
    _showToast(context, ref, (notifier) => notifier.info(message));
  }

  static void warning(BuildContext context, String message, {WidgetRef? ref}) {
    _showToast(context, ref, (notifier) => notifier.warning(message));
  }

  static void _showToast(
    BuildContext context,
    WidgetRef? ref,
    void Function(ToastNotifier notifier) emit,
  ) {
    final notifier = ref != null
        ? ref.read(toastProvider.notifier)
        : ProviderScope.containerOf(context).read(toastProvider.notifier);
    emit(notifier);
  }
}
