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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedFor(brightness),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body(
            context,
          ).copyWith(fontWeight: FontWeight.w500, color: AppColors.accent),
        ),
      ),
    );
  }
}
