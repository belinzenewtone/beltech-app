import 'package:beltech/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

enum AppCapsuleVariant { solid, subtle, outline }

enum AppCapsuleSize { sm, md, lg }

/// A compact pill badge/chip used for category labels, priority levels,
/// status indicators, and countdown badges. Optionally tappable when
/// [onTap] is provided.
class AppCapsule extends StatelessWidget {
  const AppCapsule({
    super.key,
    required this.label,
    required this.color,
    this.variant = AppCapsuleVariant.subtle,
    this.size = AppCapsuleSize.sm,
    this.icon,
    this.onTap,
  });

  final String label;
  final Color color;
  final AppCapsuleVariant variant;
  final AppCapsuleSize size;
  final IconData? icon;

  /// If non-null, wraps the chip in a [GestureDetector].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final (hPad, vPad, minHeight, fontSize, iconSize) = switch (size) {
      AppCapsuleSize.sm => (8.0, 2.0, 24.0, 11.0, 12.0), // match rn capsule
      AppCapsuleSize.md => (11.0, 5.0, 28.0, 12.5, 14.0),
      AppCapsuleSize.lg => (13.0, 6.0, 32.0, 13.5, 16.0),
    };

    final bgColor = switch (variant) {
      AppCapsuleVariant.solid => color,
      AppCapsuleVariant.subtle => color.withValues(
        alpha: brightness == Brightness.dark ? 0.14 : 0.12,
      ),
      AppCapsuleVariant.outline => Colors.transparent,
    };

    final textColor = switch (variant) {
      AppCapsuleVariant.solid => Colors.white,
      _ => color,
    };

    final border = switch (variant) {
      AppCapsuleVariant.outline => Border.all(
        color: color.withValues(alpha: 0.38),
      ),
      AppCapsuleVariant.subtle => Border.all(
        color: color.withValues(alpha: 0.22),
      ),
      AppCapsuleVariant.solid => Border.all(color: Colors.transparent),
    };

    // sm badges use a full pill; md/lg use the sm corner token
    final pillRadius = size == AppCapsuleSize.sm
        ? BorderRadius.circular(AppRadius.full)
        : BorderRadius.circular(AppRadius.sm);

    final pill = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: pillRadius,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.1,
              letterSpacing: 0.5, // matches eyebrow
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: pillRadius, child: pill),
    );
  }
}
