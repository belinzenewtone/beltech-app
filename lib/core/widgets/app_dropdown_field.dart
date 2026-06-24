import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.hintText,
    this.onChanged,
    this.validator,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final String? hintText;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondaryFor(brightness),
      ),
      dropdownColor: AppColors.surfaceFor(brightness).withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(18),
      menuMaxHeight: 320,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
