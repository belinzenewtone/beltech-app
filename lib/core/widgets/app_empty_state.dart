import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
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
              borderRadius: BorderRadius.circular(AppRadius.xxl),
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

    // Always stretch to the full available width so the empty state reads as a
    // finished, full-bleed panel rather than a narrow card floating to one side.
    content = SizedBox(width: double.infinity, child: content);

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
