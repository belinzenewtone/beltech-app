import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/tool_shortcut_grid.dart';
import 'package:flutter/material.dart';

class ProfileToolHub extends StatelessWidget {
  const ProfileToolHub({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tone: GlassCardTone.muted,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOOL HUB',
            style: AppTypography.eyebrow(context).copyWith(letterSpacing: 0.45),
          ),
          const SizedBox(height: 12),
          const ToolShortcutGrid(),
        ],
      ),
    );
  }
}
