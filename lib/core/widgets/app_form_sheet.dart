import 'dart:ui';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/theme/glass_styles.dart';
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
    const sheetRadius = BorderRadius.vertical(
      top: Radius.circular(AppRadius.xxl),
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
          child: DecoratedBox(
            // Shadow sits on the outer (un-clipped) layer so it is not cropped
            // by the ClipRRect that wraps the blur + fill.
            decoration: const BoxDecoration(
              borderRadius: sheetRadius,
              boxShadow: [
                BoxShadow(
                  color: Color(0x47000000),
                  blurRadius: 28,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: sheetRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: GlassStyles.sheetBlurSigma,
                  sigmaY: GlassStyles.sheetBlurSigma,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: GlassStyles.fillFor(brightness),
                    borderRadius: sheetRadius,
                    border: Border(
                      top: BorderSide(
                        color: GlassStyles.borderFor(brightness),
                      ),
                    ),
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
                        padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
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
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceMutedFor(
              brightness,
            ).withValues(alpha: 0.88),
            borderRadius: AppRadius.mdAll,
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
