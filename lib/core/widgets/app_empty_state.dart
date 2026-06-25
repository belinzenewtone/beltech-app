import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Standardised empty state used across all list screens.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.task_alt_rounded,
///   title: 'No tasks yet',
///   subtitle: 'Tap + to add your first task',
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.cardWrapped = true,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final bool cardWrapped;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.accent;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          icon != null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style: AppTypography.cardTitle(context),
          textAlign: icon != null ? TextAlign.center : TextAlign.start,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: AppTypography.bodySm(context),
            textAlign: icon != null ? TextAlign.center : TextAlign.start,
          ),
        ],
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    );

    if (cardWrapped) {
      content = AppCard(
        tone: AppCardTone.muted,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: content,
      );
    }

    return content;
  }
}
