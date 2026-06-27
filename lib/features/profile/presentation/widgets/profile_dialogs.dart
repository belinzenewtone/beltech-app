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
  final usernameCtrl = TextEditingController(text: profile.username);
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
                        username: usernameCtrl.text.trim(),
                        email: profile.email,
                        phone: profile.phone,
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
                maxLength: 50,
                decoration: const InputDecoration(
                  hintText: 'Full Name',
                  counterText: '',
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Full name is required';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: usernameCtrl,
                maxLength: 8,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(8),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Username',
                  counterText: '',
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Username is required';
                  if (val.length > 8) return 'Max 8 characters';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) {
                    return 'Alphanumeric and underscore only';
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
