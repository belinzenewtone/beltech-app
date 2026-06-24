import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class GlobalSearchEmptyState extends StatelessWidget {
  const GlobalSearchEmptyState({
    super.key,
    required this.recentSearches,
    required this.onRecentTap,
    required this.onClearRecent,
    required this.onShortcutTap,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onRecentTap;
  final VoidCallback onClearRecent;
  final ValueChanged<String> onShortcutTap;

  static const _shortcuts = [
    ('Today\'s expenses', Icons.today_outlined),
    ('This week', Icons.date_range_outlined),
    ('Food', Icons.restaurant_outlined),
    ('Recurring bills', Icons.repeat_rounded),
    ('Budget', Icons.savings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GlassCard(
          tone: GlassCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick searches',
                style: AppTypography.cardTitle(context),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, icon) in _shortcuts)
                    AppCapsule(
                      label: label,
                      color: AppColors.accent,
                      variant: AppCapsuleVariant.subtle,
                      size: AppCapsuleSize.md,
                      icon: icon,
                      onTap: () {
                        AppHaptics.lightImpact();
                        onShortcutTap(label);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        if (recentSearches.isNotEmpty) ...[
          const SizedBox(height: 12),
          GlassCard(
            tone: GlassCardTone.muted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Recent',
                      style: AppTypography.cardTitle(context),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onClearRecent,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final search in recentSearches)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      AppHaptics.lightImpact();
                      onRecentTap(search);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              search,
                              style: AppTypography.bodySm(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.north_west,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
