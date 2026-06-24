import 'dart:io';

import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/ota/shorebird_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A persistent top banner that appears when a Shorebird patch has been
/// downloaded and is ready to apply on the next app restart.
///
/// Styled to match [OfflineBanner] but with an accent-teal colour so it reads
/// as a positive action rather than an error.
///
/// Tapping "Restart" closes the app on Android (which forces a cold restart
/// that Shorebird uses to swap in the patch).  On iOS the user is shown a
/// message since iOS doesn't allow programmatic exits.
class PatchReadyBanner extends ConsumerStatefulWidget {
  const PatchReadyBanner({super.key});

  @override
  ConsumerState<PatchReadyBanner> createState() => _PatchReadyBannerState();
}

class _PatchReadyBannerState extends ConsumerState<PatchReadyBanner> {
  /// Set to true when the user taps ✕ — the banner hides for this session
  /// but re-appears the next time the app is launched (patch is still ready).
  bool _dismissedThisSession = false;

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(patchRestartRequiredProvider);
    final visible = ready && !_dismissedThisSession;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: child,
      ),
      child: visible
          ? ColoredBox(
              key: const ValueKey('patch-ready'),
              color: const Color(0xFF0A7A6E), // deep teal — positive action
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.system_update_alt_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Update ready — restart to apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Restart button
                      GestureDetector(
                        onTap: _restart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Restart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Dismiss for this session
                      GestureDetector(
                        onTap: () {
                          AppHaptics.lightImpact();
                          setState(() => _dismissedThisSession = true);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('patch-not-ready')),
    );
  }

  void _restart() {
    AppHaptics.mediumImpact();
    if (Platform.isAndroid) {
      // Closing the Android task causes Android to cold-start the app on
      // next open, at which point Shorebird applies the waiting patch.
      SystemNavigator.pop();
    } else {
      // On iOS, programmatic exit is not permitted. Show guidance instead.
      _showIosRestartGuidance();
    }
  }

  void _showIosRestartGuidance() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restart Required'),
        content: const Text(
          'To apply the update, close BELTECH from the app switcher and reopen it.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _dismissedThisSession = true);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
