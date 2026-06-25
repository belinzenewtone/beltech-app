import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsSecurityCard extends ConsumerWidget {
  const SettingsSecurityCard({super.key, required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionLockState = ref.watch(sessionLockSettingsProvider);
    final sessionLockWriteState = ref.watch(
      sessionLockSettingsControllerProvider,
    );
    final graceSeconds = sessionLockState.valueOrNull?.gracePeriodSeconds ?? 15;

    return AppCard(
      tone: AppCardTone.muted,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsRow(
            icon: Icons.fingerprint_outlined,
            title: 'Biometric Lock',
            subtitle: state.biometricSupported
                ? 'Use fingerprint or face to unlock'
                : 'Not supported on this device',
            trailing: Switch.adaptive(
              value: state.biometricEnabled,
              onChanged: state.biometricSupported
                  ? (value) async {
                      await ref
                          .read(authProvider.notifier)
                          .setBiometricEnabled(value);
                    }
                  : null,
            ),
            isFirst: true,
          ),
          SettingsRow(
            icon: Icons.timer_outlined,
            title: 'Relock Delay',
            subtitle: 'Grace period before requiring biometric again',
            trailing: _GracePeriodSelector(
              value: graceSeconds,
              onChanged: sessionLockWriteState.isLoading
                  ? null
                  : (value) async {
                      if (value == null) return;
                      await ref
                          .read(sessionLockSettingsControllerProvider.notifier)
                          .setGracePeriodSeconds(value);
                    },
            ),
            dividerAbove: true,
          ),
          Divider(
            height: 1,
            indent: 56,
            color: AppColors.border.withValues(alpha: 0.35),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Authenticate Now',
              icon: state.isAuthenticating ? null : Icons.fingerprint,
              loading: state.isAuthenticating,
              fullWidth: true,
              onPressed: state.isAuthenticating
                  ? null
                  : () async {
                      final ok = await ref
                          .read(authProvider.notifier)
                          .authenticateNow();
                      if (context.mounted) {
                        if (ok) {
                          AppFeedback.success(
                            context,
                            'Authentication successful.',
                          );
                        } else {
                          AppFeedback.error(context, 'Authentication failed.');
                        }
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _GracePeriodSelector extends StatelessWidget {
  const _GracePeriodSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
        dropdownColor: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        style: AppTypography.body(
          context,
        ).copyWith(color: AppColors.textSecondary),
        underline: const SizedBox.shrink(),
        items: SessionLockSettingsRepository.supportedGracePeriods
            .map(
              (seconds) => DropdownMenuItem<int>(
                value: seconds,
                child: Text(_labelForGracePeriod(seconds)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _labelForGracePeriod(int seconds) {
    if (seconds == 0) return 'Instant';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }
}
