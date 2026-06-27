import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Simple 6-digit PIN setup/confirmation dialog.
///
/// Returns the entered PIN if the user enables it, or `null` if cancelled.
class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({super.key});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _valid {
    return _pinController.text.length == 6 &&
        _confirmController.text == _pinController.text;
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _valid) {
      Navigator.of(context).pop(_pinController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        'Set Up PIN',
        style: AppTypography.cardTitle(context),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PinField(
              label: 'PIN',
              controller: _pinController,
              onChanged: () => setState(() {}),
              validator: (value) {
                if (value == null || value.length != 6) {
                  return 'Enter 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _PinField(
              label: 'Confirm PIN',
              controller: _confirmController,
              onChanged: () => setState(() {}),
              validator: (value) {
                if (value == null || value.length != 6) {
                  return 'Enter 6 digits';
                }
                if (value != _pinController.text) {
                  return 'PINs do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Enable',
          onPressed: _valid ? _submit : null,
        ),
      ],
    );
  }
}

class _PinField extends StatefulWidget {
  const _PinField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final FormFieldValidator<String>? validator;

  @override
  State<_PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<_PinField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AppTypography.body(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$length/6',
              style: AppTypography.bodySm(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}
