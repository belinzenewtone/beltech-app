import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppFormSheet extends StatelessWidget {
  const AppFormSheet({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.subtitle,
    this.footer,
    this.controller,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback onClose;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(brightness),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxl),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.borderFor(
                    brightness,
                  ).withValues(alpha: 0.55),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderFor(
                      brightness,
                    ).withValues(alpha: 0.8),
                    borderRadius: AppRadius.fullAll,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.pageTitle(context),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: AppTypography.bodySm(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _SheetCloseButton(onPressed: onClose),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    controller: controller,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: footer,
                  )
                else
                  SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.fullAll,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceMutedFor(
              brightness,
            ).withValues(alpha: 0.88),
            borderRadius: AppRadius.fullAll,
            border: Border.all(
              color: AppColors.borderFor(brightness).withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: AppColors.textSecondaryFor(brightness),
          ),
        ),
      ),
    );
  }
}
