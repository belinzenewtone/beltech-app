import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class ProfileSecuritySection extends StatelessWidget {
  const ProfileSecuritySection({
    super.key,
    required this.onSignOut,
    required this.signingOut,
  });

  final VoidCallback onSignOut;
  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      child: InkWell(
        onTap: signingOut ? null : onSignOut,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign out',
                  style: AppTypography.bodyMd(context),
                ),
              ),
              if (signingOut)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
