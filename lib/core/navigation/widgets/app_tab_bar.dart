import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Floating bottom tab bar that mirrors the RN navigation geometry:
/// - rounded outer shell
/// - per-tab active pill behind icon
/// - always-visible compact labels
///
/// Matches the RN TAB_BAR_HEIGHT = 64 pill total (paddingV*2 + icon 28 + gap + label).
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.height = 56,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<AppTabItem> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final mutedColor = AppColors.textMutedFor(brightness);
    final accentLight = AppColors.accentLight; // like RN colors.accentLight
    final itemDuration = AppMotion.duration(
      context,
      normalMs: 140,
      reducedMs: 0,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final resolvedHeight = height + ((textScale - 1) * 12).clamp(0.0, 10.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        height: resolvedHeight,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Expanded(
              child: _AppTabBarItem(
                item: item,
                selected: index == selectedIndex,
                accentLight: accentLight,
                mutedColor: mutedColor,
                duration: itemDuration,
                onTap: () {
                  AppHaptics.lightImpact();
                  onTap(index);
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AppTabBarItem extends StatelessWidget {
  const _AppTabBarItem({
    required this.item,
    required this.selected,
    required this.accentLight,
    required this.mutedColor,
    required this.duration,
    required this.onTap,
  });

  final AppTabItem item;
  final bool selected;
  final Color accentLight;
  final Color mutedColor;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? accentLight : mutedColor;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    opacity: selected ? 1 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAccentAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentLight.withValues(alpha: 0.20)),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1 : 0.88,
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: iconColor,
                height: 1.1,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class AppTabItem {
  const AppTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
