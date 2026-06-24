import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// The unified page wrapper every tab screen and secondary screen uses.
///
/// Provides:
/// - Plain solid background matching the React Native design
/// - Optional scroll mode vs fixed Column
/// - Safe-area aware top padding
/// - Consistent horizontal padding via [AppSpacing.screenHorizontal]
///
/// Usage:
/// ```dart
/// PageShell(
///   child: Column(children: [...]),
/// )
/// ```
class PageShell extends StatefulWidget {
  const PageShell({
    super.key,
    required this.child,
    this.scrollable = true,
    this.horizontalPadding = AppSpacing.screenHorizontal,
    this.topPadding = AppSpacing.screenTop,
    this.bottomPadding = AppSpacing.contentBottomSafe,
    this.controller,
  });

  final Widget child;
  final bool scrollable;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final ScrollController? controller;

  @override
  State<PageShell> createState() => _PageShellState();
}

class _PageShellState extends State<PageShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealCtrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _opacity = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealCtrl.forward();
    });
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final effectiveBottom = widget.bottomPadding + safeBottom;
    final effectiveTop =
        widget.scrollable ? AppSpacing.listGap : widget.topPadding;

    // Non-scrollable bottom: if bottomPadding was explicitly overridden from
    // its default (contentBottomSafe is the scrollable default), honour it
    // directly so callers can pin the input flush with the nav bar. Otherwise
    // keep the old symmetric topPadding behaviour for screens that don't set it.
    final nonScrollableBottom =
        widget.bottomPadding == AppSpacing.contentBottomSafe
            ? widget.topPadding + safeBottom
            : widget.bottomPadding + safeBottom;

    Widget content = widget.scrollable
        ? SingleChildScrollView(
            controller: widget.controller,
            padding: EdgeInsets.fromLTRB(
              widget.horizontalPadding,
              effectiveTop,
              widget.horizontalPadding,
              effectiveBottom,
            ),
            child: widget.child,
          )
        : Padding(
            padding: EdgeInsets.fromLTRB(
              widget.horizontalPadding,
              widget.topPadding,
              widget.horizontalPadding,
              nonScrollableBottom,
            ),
            child: widget.child,
          );

    if (!reduceMotion) {
      content = FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: content),
      );
    }

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: content,
      ),
    );
  }
}
