import 'package:beltech/core/widgets/permission_rationale_sheet.dart';
import 'package:flutter/material.dart';

Future<bool> showPermissionRationaleSheet({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String description,
  required List<String> bulletPoints,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PermissionRationaleSheet(
      icon: icon,
      title: title,
      description: description,
      bulletPoints: bulletPoints,
      onAllow: () => Navigator.of(context).pop(true),
      onDismiss: () => Navigator.of(context).pop(false),
    ),
  );
  return result ?? false;
}
