import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// In-screen section label with optional action link on the right.
///
/// Usage:
/// ```dart
/// SectionHeader('Recent Transactions')
/// SectionHeader('Tasks', action: TextButton(onPressed: ..., child: Text('See all')))
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.label, {
    super.key,
    this.action,
    this.topPadding = 0,
    this.bottomPadding = 10,
  });

  final String label;
  final Widget? action;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.sectionTitle(context)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
