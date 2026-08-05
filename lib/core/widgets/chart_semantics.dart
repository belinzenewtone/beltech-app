import 'package:flutter/material.dart';

/// Attaches a spoken `Semantics` label to any chart widget.
///
/// CustomPainter charts are invisible to accessibility services unless
/// explicitly labelled. Wrap any chart in a [ChartSemantics] to give
/// screen-reader users a textual description.
///
/// Example:
/// ```dart
/// ChartSemantics(
///   label: 'Spending trend, 6 months, highest in March',
///   child: CustomPaint(painter: ...),
/// )
/// ```
class ChartSemantics extends StatelessWidget {
  const ChartSemantics({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: MergeSemantics(child: child),
    );
  }
}
