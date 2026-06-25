import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'package:beltech/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showEditProfileDialog(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) async {
  final nameCtrl = TextEditingController(text: profile.name);
  final emailCtrl = TextEditingController(text: profile.email);
  final phoneCtrl = TextEditingController(text: profile.phone);
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return AppFormSheet(
        title: 'Edit Profile',
        onClose: () => Navigator.pop(context),
        footer: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Save',
                fullWidth: true,
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }
                  await ref
                      .read(profileWriteControllerProvider.notifier)
                      .updateProfile(
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                  final writeState = ref.read(profileWriteControllerProvider);
                  if (context.mounted && !writeState.hasError) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                maxLength: 10,
                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                decoration: const InputDecoration(
                  hintText: 'Username',
                  counterText: '',
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Username is required';
                  if (val.length > 10) return 'Max 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(hintText: 'Email'),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(hintText: 'Phone'),
                validator: (v) {
                  final phone = v?.trim() ?? '';
                  if (phone.isEmpty) {
                    return 'Phone is required';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                    return 'Phone must be exactly 10 digits';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showPasswordDialog(BuildContext context, WidgetRef ref) async {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return AppFormSheet(
        title: 'Change Password',
        onClose: () => Navigator.pop(context),
        footer: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Update',
                fullWidth: true,
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }
                  await ref
                      .read(profileWriteControllerProvider.notifier)
                      .changePassword(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                  final writeState = ref.read(profileWriteControllerProvider);
                  if (context.mounted && !writeState.hasError) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Current password'),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Current password required'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'New password'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirm new password',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != newCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
