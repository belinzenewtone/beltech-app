import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_dropdown_field.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsSecurityCard extends ConsumerWidget {
  const SettingsSecurityCard({super.key, required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionLockState = ref.watch(sessionLockSettingsProvider);
    final sessionLockWriteState =
        ref.watch(sessionLockSettingsControllerProvider);

    return Column(
      children: [
        GlassCard(
          tone: GlassCardTone.muted,
          child: Row(
            children: [
              const Icon(Icons.fingerprint_outlined, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biometric Lock',
                        style: AppTypography.cardTitle(context)),
                    const SizedBox(height: 4),
                    Text(
                      state.biometricSupported
                          ? 'Use fingerprint/face to unlock secure actions'
                          : 'Biometrics not supported on this device',
                      style: AppTypography.bodySm(context),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: state.biometricEnabled,
                onChanged: state.biometricSupported
                    ? (value) async {
                        await ref
                            .read(authProvider.notifier)
                            .setBiometricEnabled(value);
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.listGap),
        GlassCard(
          tone: GlassCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Relock Delay',
                            style: AppTypography.cardTitle(context)),
                        const SizedBox(height: 4),
                        Text(
                          'Choose how long the app can stay in the background before biometric relock is required.',
                          style: AppTypography.bodySm(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppDropdownField<int>(
                label: 'Grace Period',
                value: sessionLockState.valueOrNull?.gracePeriodSeconds,
                hintText: 'Select delay',
                onChanged: sessionLockWriteState.isLoading
                    ? null
                    : (value) async {
                        if (value == null) {
                          return;
                        }
                        await ref
                            .read(
                              sessionLockSettingsControllerProvider.notifier,
                            )
                            .setGracePeriodSeconds(value);
                      },
                items: SessionLockSettingsRepository.supportedGracePeriods
                    .map(
                      (seconds) => DropdownMenuItem<int>(
                        value: seconds,
                        child: Text(_labelForGracePeriod(seconds)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.listGap),
        GlassCard(
          tone: GlassCardTone.muted,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isAuthenticating
                  ? null
                  : () async {
                      final ok = await ref
                          .read(authProvider.notifier)
                          .authenticateNow();
                      if (context.mounted) {
                        if (ok) {
                          AppFeedback.success(
                              context, 'Authentication successful.');
                        } else {
                          AppFeedback.error(context, 'Authentication failed.');
                        }
                      }
                    },
              icon: state.isAuthenticating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: const Text('Authenticate Now'),
            ),
          ),
        ),
      ],
    );
  }

  String _labelForGracePeriod(int seconds) {
    if (seconds == 0) {
      return 'Instant';
    }
    if (seconds < 60) {
      return '${seconds}s';
    }
    return '${seconds ~/ 60}m';
  }
}
