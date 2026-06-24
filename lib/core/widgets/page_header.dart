import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Consistent screen header for every tab and secondary screen.
///
/// Slots:
/// - [eyebrow]  — small caps label above the title (optional)
/// - [title]    — main page title (required)
/// - [subtitle] — supporting text below title (optional)
/// - [action]   — widget pinned to the top-right (optional)
/// - [leading]  — widget to the left of the title block (optional)
///
/// Usage:
/// ```dart
/// PageHeader(
///   eyebrow: 'YOUR DAY',
///   title: 'Good Morning, Belinze',
///   subtitle: "Here's your day at a glance",
///   action: UserAvatarButton(onTap: ...),
/// )
/// ```
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.action,
    this.leading,
    this.bottomPadding = 4,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? action;
  final Widget? leading;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: leading!,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              eyebrow!.toUpperCase(),
                              style: AppTypography.eyebrow(context),
                            ),
                          ),
                        Text(
                          title,
                          style: AppTypography.pageTitle(context).copyWith(
                            fontSize: 26,
                            height: 32 / 26,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: AppTypography.bodySm(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: action!,
            ),
          ],
        ],
      ),
    );
  }
}
