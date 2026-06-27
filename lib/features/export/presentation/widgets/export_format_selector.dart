import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/features/export/domain/entities/export_format.dart';
import 'package:flutter/material.dart';

class ExportFormatSelector extends StatelessWidget {
  const ExportFormatSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ExportFormat selected;
  final ValueChanged<ExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: ExportFormat.values.map((format) {
        final isSelected = format == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: format == ExportFormat.values.last ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => onChanged(format),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.16)
                      : AppColors.surfaceMutedFor(brightness),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.55)
                        : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  format.name,
                  style: AppTypography.bodyMd(context).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
