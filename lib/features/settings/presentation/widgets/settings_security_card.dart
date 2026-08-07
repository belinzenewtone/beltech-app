import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_dropdown_field.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:beltech/features/settings/presentation/widgets/pin_setup_dialog.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsSecurityCard extends ConsumerWidget {
  const SettingsSecurityCard({super.key, required this.state});

  final AuthState state;

  Future<void> _onBiometricToggle(BuildContext context, WidgetRef ref, bool value) async {
    if (!value) {
      await ref.read(authProvider.notifier).setBiometricEnabled(false);
      return;
    }

    final repository = ref.read(authRepositoryProvider);
    final pinEnabled = await repository.isPinEnabled();
    final pinSet = await repository.isPinSet();
    if (!pinEnabled || !pinSet) {
      if (!context.mounted) return;
      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PinSetupDialog(),
      );
      if (pin == null || !context.mounted) return;
      await ref.read(pinControllerProvider.notifier).setPin(pin);
      if (!context.mounted) return;
      final pinState = ref.read(pinControllerProvider);
      if (pinState.hasError) {
        AppFeedback.error(
          context,
          '${pinState.error}'.replaceFirst('Exception: ', ''),
        );
        return;
      }
      await ref.read(authProvider.notifier).setPinEnabled(true);
      if (!context.mounted) return;
    }

    await ref.read(authProvider.notifier).setBiometricEnabled(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionLockState = ref.watch(sessionLockSettingsProvider);
    final sessionLockWriteState = ref.watch(
      sessionLockSettingsControllerProvider,
    );
    final graceSeconds = sessionLockState.value?.gracePeriodSeconds ?? 15;

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
                  ? (value) async => _onBiometricToggle(context, ref, value)
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
    return AppDropdownPicker<int>(
      hint: 'Select grace period',
      value: value,
      items: SessionLockSettingsRepository.supportedGracePeriods,
      labelFor: _labelForGracePeriod,
      onChanged: (v) => onChanged?.call(v),
    );
  }

  String _labelForGracePeriod(int seconds) {
    if (seconds == 0) return 'Instant';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }
}
