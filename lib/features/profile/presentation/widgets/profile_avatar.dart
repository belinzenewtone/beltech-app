import 'dart:convert';
import 'dart:typed_data';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.onCameraTap,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final onSurface = AppColors.textPrimaryFor(brightness);
    final borderColor = AppColors.surfaceFor(brightness);
    final image = _avatarImage(avatarUrl);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.accent,
          backgroundImage: image,
          child: image == null
              ? Text(
                  name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Tooltip(
            message: 'Change profile photo',
            child: Semantics(
              label: 'Change profile photo',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: onCameraTap,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: brightness == Brightness.light
                          ? Colors.white.withValues(alpha: 0.96)
                          : AppColors.surfaceMutedFor(brightness),
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.textSecondaryFor(brightness),
                      size: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider<Object>? _avatarImage(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('http')) {
      return NetworkImage(value);
    }
    if (value.startsWith('data:image')) {
      final bytes = _decodeDataUri(value);
      if (bytes != null) {
        return MemoryImage(bytes);
      }
    }
    return null;
  }

  Uint8List? _decodeDataUri(String dataUri) {
    final comma = dataUri.indexOf(',');
    if (comma == -1 || comma >= dataUri.length - 1) {
      return null;
    }
    try {
      final base64Value = dataUri.substring(comma + 1);
      return base64Decode(base64Value);
    } catch (_) {
      return null;
    }
  }
}
