import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsNewBanner extends StatefulWidget {
  const WhatsNewBanner({
    super.key,
    required this.version,
    required this.changelog,
    this.onDismiss,
  });

  final String version;
  final String changelog;
  final VoidCallback? onDismiss;

  static const _seenKey = 'whats_new_last_seen_version';

  static Future<bool> shouldShow(String currentVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_seenKey) ?? '';
    return lastSeen != currentVersion;
  }

  static Future<void> markSeen(String currentVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenKey, currentVersion);
  }

  @override
  State<WhatsNewBanner> createState() => _WhatsNewBannerState();
}

class _WhatsNewBannerState extends State<WhatsNewBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.accent.withValues(
          alpha: brightness == Brightness.light ? 0.08 : 0.14,
        ),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showChangelog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "What's new in v${widget.version}",
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _dismissBanner,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismissBanner() {
    setState(() => _dismissed = true);
    widget.onDismiss?.call();
  }

  void _showChangelog(BuildContext context) {
    final notes = widget.changelog
        .split('||')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    showAppDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        title: Text(
          "What's New in v${widget.version}",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: notes
                .map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• $note',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dismissBanner();
              widget.onDismiss?.call();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
