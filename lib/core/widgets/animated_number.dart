import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Smoothly tweens a numeric value whenever it changes.
///
/// Uses a [StatefulWidget] so it can remember the *previous* value and use it
/// as the tween `begin`. This prevents the jarring 0→N count-up that happened
/// previously when the widget was re-mounted (e.g. on tab switch or list
/// rebuild). The animation only runs when [value] actually changes.
///
/// Usage:
/// ```dart
/// AnimatedNumber(
///   value: overview.totalSpend.toDouble(),
///   formatter: CurrencyFormatter.money,
/// )
/// ```
class AnimatedNumber extends StatefulWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  /// The target numeric value to animate toward.
  final double value;

  /// Converts the tweened double into a display string (e.g. "KES 4,200").
  final String Function(double) formatter;

  /// Text style. Defaults to [AppTypography.amountLg].
  final TextStyle? style;

  final Duration duration;
  final Curve curve;
  final TextAlign? textAlign;
  final int maxLines;
  final TextOverflow overflow;

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber> {
  late double _previousValue;

  @override
  void initState() {
    super.initState();
    // On first mount start from the target directly — no count-up from zero.
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // Remember where this tween started so the next update doesn't reset.
      _previousValue = old.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = widget.style ?? AppTypography.amountLg(context);
    return TweenAnimationBuilder<double>(
      // begin = last known value so we never animate from 0 on remount.
      tween: Tween<double>(begin: _previousValue, end: widget.value),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, animatedValue, _) {
        return Text(
          widget.formatter(animatedValue),
          style: resolvedStyle,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}
