import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A shimmer placeholder that mirrors the shape of content loading.
///
/// Usage:
/// ```dart
/// AppSkeleton(width: double.infinity, height: 18)       // text line
/// AppSkeleton(width: 80, height: 80, circular: true)    // avatar
/// AppSkeleton.card(context)                             // full card block
/// ```
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.circular = false,
  });

  final double width;
  final double height;
  final double borderRadius;
  final bool circular;

  /// Pre-built card-shaped skeleton (matches GlassCard proportions).
  static Widget card(BuildContext context, {double height = 88}) {
    return AppSkeleton(
      width: double.infinity,
      height: height,
      borderRadius: 22,
    );
  }

  /// A single shimmer text line.
  static Widget line(BuildContext context, {double width = double.infinity, double height = 14}) {
    return AppSkeleton(width: width, height: height, borderRadius: 6);
  }

  /// Two-line text block (title + subtitle).
  static Widget textBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton.line(context, width: 160, height: 16),
        const SizedBox(height: 6),
        AppSkeleton.line(context, width: 110, height: 13),
      ],
    );
  }

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final base = brightness == Brightness.light
        ? const Color(0xFFE2EAF4)
        : AppColors.surfaceMuted;
    final highlight = brightness == Brightness.light
        ? const Color(0xFFF0F6FF)
        : AppColors.surface;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final color = reduceMotion
            ? base
            : Color.lerp(base, highlight, _shimmer.value)!;
        return Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.circular
                ? BorderRadius.circular(999)
                : BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// ── Composite skeletons ──────────────────────────────────────────────────────

/// Skeleton for a TaskItemCard.
class TaskCardSkeleton extends StatelessWidget {
  const TaskCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          const AppSkeleton(width: 4, height: 72, borderRadius: 10),
          const SizedBox(width: 10),
          const AppSkeleton(width: 24, height: 24, circular: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.line(context, width: 180, height: 15),
                const SizedBox(height: 6),
                AppSkeleton.line(context, width: 110, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a transaction row.
class TransactionSkeleton extends StatelessWidget {
  const TransactionSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppSkeleton(width: 40, height: 40, circular: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton.line(context, width: 140, height: 14),
              const SizedBox(height: 5),
              AppSkeleton.line(context, width: 80, height: 12),
            ],
          ),
        ),
        AppSkeleton.line(context, width: 64, height: 14),
      ],
    );
  }
}

/// Skeleton list for the Home screen overview.
class HomeSkeletonList extends StatelessWidget {
  const HomeSkeletonList({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: AppSkeleton.card(context, height: 76)),
            const SizedBox(width: 12),
            Expanded(child: AppSkeleton.card(context, height: 76)),
          ],
        ),
        const SizedBox(height: 14),
        AppSkeleton.card(context, height: 68),
        const SizedBox(height: 14),
        AppSkeleton.card(context, height: 68),
        const SizedBox(height: 14),
        AppSkeleton.card(context, height: 130),
        const SizedBox(height: 14),
        for (int i = 0; i < 3; i++) ...[
          AppSkeleton.card(context, height: 64),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Skeleton list for the Finance screen.
class FinanceSkeletonList extends StatelessWidget {
  const FinanceSkeletonList({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: AppSkeleton.card(context, height: 72)),
            const SizedBox(width: 10),
            Expanded(child: AppSkeleton.card(context, height: 72)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: AppSkeleton.card(context, height: 72)),
            const SizedBox(width: 10),
            Expanded(child: AppSkeleton.card(context, height: 72)),
          ],
        ),
        const SizedBox(height: 14),
        AppSkeleton.card(context, height: 160),
        const SizedBox(height: 14),
        for (int i = 0; i < 4; i++) ...[
          const TransactionSkeleton(),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
