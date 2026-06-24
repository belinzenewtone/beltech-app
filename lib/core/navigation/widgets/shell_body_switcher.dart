import 'package:flutter/material.dart';

class ShellBodySwitcher extends StatefulWidget {
  const ShellBodySwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
    required this.reduceMotion,
  });

  final int currentIndex;
  final List<Widget> children;
  final bool reduceMotion;

  @override
  State<ShellBodySwitcher> createState() => _ShellBodySwitcherState();
}

class _ShellBodySwitcherState extends State<ShellBodySwitcher> {
  late int _previousIndex = widget.currentIndex;
  bool _animating = false;
  int _transitionToken = 0;

  Duration get _transitionDuration =>
      widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 170);

  @override
  void didUpdateWidget(covariant ShellBodySwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == oldWidget.currentIndex) {
      return;
    }
    setState(() {
      _previousIndex = oldWidget.currentIndex;
      _animating = true;
    });
    final currentToken = ++_transitionToken;
    Future<void>.delayed(_transitionDuration, () {
      if (!mounted || currentToken != _transitionToken) {
        return;
      }
      setState(() {
        _animating = false;
        _previousIndex = widget.currentIndex;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (index) {
        final active = index == widget.currentIndex;
        final visible = active || (_animating && index == _previousIndex);
        return _ShellBodyItem(
          active: active,
          visible: visible,
          duration: _transitionDuration,
          child: widget.children[index],
        );
      }),
    );
  }
}

class _ShellBodyItem extends StatelessWidget {
  const _ShellBodyItem({
    required this.active,
    required this.visible,
    required this.duration,
    required this.child,
  });

  final bool active;
  final bool visible;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return Offstage(
        offstage: true,
        child: TickerMode(enabled: false, child: child),
      );
    }
    return IgnorePointer(
      ignoring: !active,
      child: TickerMode(
        enabled: visible,
        child: AnimatedOpacity(
          duration: duration,
          curve: Curves.easeOutCubic,
          opacity: active ? 1 : 0,
          child: ExcludeSemantics(
            excluding: !active,
            child: child,
          ),
        ),
      ),
    );
  }
}
