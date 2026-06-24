import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Quick-prompt pill row — pills scroll horizontally so they never wrap
/// to a second line and don't consume extra vertical space.
class AssistantPromptGrid extends StatelessWidget {
  const AssistantPromptGrid({
    required this.prompts,
    required this.onPromptTap,
    super.key,
  });

  final List<String> prompts;
  final Future<void> Function(String) onPromptTap;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (int i = 0; i < prompts.length; i++) ...[
            _PromptPill(
              label: prompts[i],
              onTap: () => onPromptTap(prompts[i]),
            ),
            if (i < prompts.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PromptPill extends StatelessWidget {
  const _PromptPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final chipBackground =
        AppColors.surfaceMutedFor(brightness).withValues(alpha: 0.7);
    final chipBorder = AppColors.borderFor(brightness).withValues(alpha: 0.78);

    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 40,
          maxWidth: 220,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: chipBackground,
            border: Border.all(color: chipBorder),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
