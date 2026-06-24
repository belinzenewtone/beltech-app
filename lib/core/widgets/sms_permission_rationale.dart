import 'package:beltech/core/widgets/permission_rationale.dart';
import 'package:flutter/material.dart';

Future<bool> showSmsPermissionRationale(BuildContext context) {
  return showPermissionRationaleSheet(
    context: context,
    icon: Icons.sms_outlined,
    title: 'SMS Access',
    description:
        'BELTECH reads M-Pesa transaction messages to automatically track your expenses.',
    bulletPoints: const [
      'Only M-Pesa messages are processed',
      'Messages stay on your device',
      'No messages are sent to any server',
      'You can disable this anytime in Settings',
    ],
  );
}
