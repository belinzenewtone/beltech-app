import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Consistent wrapper for all secondary (non-tab) screens.
///
/// Renders a back-arrow header, the same atmospheric glow as [PageShell],
/// and consistent horizontal padding.
class SecondaryPageShell extends StatelessWidget {
  const SecondaryPageShell({
    super.key,
    required this.title,
    required this.child,
    this.scrollable = true,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final bool scrollable;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: AppColors.backgroundFor(brightness),
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: floatingActionButton,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 8,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(title, style: AppTypography.sectionTitle(context)),
            actions: actions == null
                ? null
                : [
                    for (final action in actions!) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: action,
                      ),
                    ],
                  ],
          ),
          body: scrollable
              ? SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    8,
                    AppSpacing.screenHorizontal,
                    AppSpacing.contentBottomSafe + bottomSafe,
                  ),
                  child: child,
                )
              : Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    8,
                    AppSpacing.screenHorizontal,
                    bottomSafe,
                  ),
                  child: child,
                ),
        ),
      ),
    );
  }
}
