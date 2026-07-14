import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.accent,
    this.foregroundColor = AppColors.textPrimary,
    this.size = 56,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final bool isLoading;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            child: widget.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: widget.foregroundColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(widget.icon),
          ),
        ),
      ),
    );
  }
}
