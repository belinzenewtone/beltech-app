import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class BeltechLogo extends StatelessWidget {
  const BeltechLogo({
    super.key,
    this.size = 92,
    this.borderRadius = 22,
  });

  static const String assetPath = 'assets/branding/beltech_logo.jpeg';

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1932), Color(0xFF050D1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 0.62,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Icon(
                      Icons.hub_outlined,
                      size: 38,
                      color: AppColors.textPrimary,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
