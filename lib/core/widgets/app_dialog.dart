import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  Color barrierColor = const Color(0xB3000000),
  String? barrierLabel,
  RouteSettings? routeSettings,
}) {
  final transitionDuration = AppMotion.dialog(context);
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final capturedThemes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );

  return showGeneralDialog<T>(
    context: context,
    routeSettings: routeSettings,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel:
        barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    pageBuilder: (dialogContext, _, __) {
      Widget child = Builder(builder: builder);
      if (useSafeArea) {
        child = SafeArea(child: child);
      }
      return capturedThemes.wrap(child);
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      if (transitionDuration == Duration.zero) {
        return child;
      }
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        child: child,
      );
    },
  );
}

/// Shows a destructive-action confirmation dialog.
/// Returns `true` if the user confirms, `false` / `null` if they cancel.
Future<bool?> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Delete',
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title, style: AppTypography.sectionTitle(dialogContext)),
      content: Text(body, style: AppTypography.bodyMd(dialogContext)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: confirmLabel,
          variant: AppButtonVariant.danger,
          size: AppButtonSize.sm,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
}
