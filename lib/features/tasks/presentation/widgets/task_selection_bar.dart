import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Appears when the user is in multi-select mode.
/// Shows count + bulk action buttons (complete, archive, delete).
class TaskSelectionBar extends StatelessWidget {
  const TaskSelectionBar({
    super.key,
    required this.selectedCount,
    required this.isLoading,
    required this.onComplete,
    required this.onArchive,
    required this.onDelete,
  });

  final int selectedCount;
  final bool isLoading;
  final VoidCallback onComplete;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || selectedCount == 0;
    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$selectedCount selected',
            style: AppTypography.bodySm(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Complete',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                icon: Icons.done_all_rounded,
                onPressed: disabled ? null : onComplete,
              ),
              AppButton(
                label: 'Archive',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                icon: Icons.archive_outlined,
                onPressed: disabled ? null : onArchive,
              ),
              AppButton(
                label: 'Delete',
                variant: AppButtonVariant.danger,
                size: AppButtonSize.sm,
                icon: Icons.delete_outline_rounded,
                onPressed: disabled ? null : onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
