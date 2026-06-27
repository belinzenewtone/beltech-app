import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:beltech/features/settings/presentation/widgets/pin_setup_dialog.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_security_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ScreenLockTab { biometric, pin }

class ScreenLockScreen extends ConsumerStatefulWidget {
  const ScreenLockScreen({super.key});

  @override
  ConsumerState<ScreenLockScreen> createState() => _ScreenLockScreenState();
}

class _ScreenLockScreenState extends ConsumerState<ScreenLockScreen> {
  _ScreenLockTab _selectedTab = _ScreenLockTab.biometric;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return SecondaryPageShell(
      title: 'Screen Lock',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSegmentedPill<_ScreenLockTab>(
            options: const [
              SettingsSegmentOption(value: _ScreenLockTab.biometric, label: 'Biometric'),
              SettingsSegmentOption(value: _ScreenLockTab.pin, label: 'PIN'),
            ],
            selected: _selectedTab,
            onSelected: (tab) => setState(() => _selectedTab = tab),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          switch (_selectedTab) {
            _ScreenLockTab.biometric => _BiometricTab(state: authState),
            _ScreenLockTab.pin => const _PinTab(),
          },
        ],
      ),
    );
  }
}

class _BiometricTab extends ConsumerWidget {
  const _BiometricTab({required this.state});

  final AsyncValue<AuthState> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      data: (value) => SettingsSecurityCard(state: value),
      loading: () => const AppCard(
        tone: AppCardTone.muted,
        child: SizedBox(
          height: 200,
          child: Center(child: LoadingIndicator()),
        ),
      ),
      error: (_, _) => AppCard(
        tone: AppCardTone.muted,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger),
            const SizedBox(height: 8),
            Text(
              'Unable to load security settings',
              style: AppTypography.bodySm(context),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(authProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTab extends ConsumerStatefulWidget {
  const _PinTab();

  @override
  ConsumerState<_PinTab> createState() => _PinTabState();
}

class _PinTabState extends ConsumerState<_PinTab> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _pinSet = false;
  bool _isLoading = true;
  bool _togglingPin = false;

  @override
  void initState() {
    super.initState();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final repository = ref.read(authRepositoryProvider);
    final pinSet = await repository.isPinSet();
    if (mounted) {
      setState(() {
        _pinSet = pinSet;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _fieldsValid {
    if (_pinSet && _currentController.text.length != 6) return false;
    if (_newController.text.length != 6) return false;
    return _confirmController.text == _newController.text;
  }

  Future<void> _updatePin() async {
    if (!_fieldsValid || !_formKey.currentState!.validate()) return;
    await ref.read(pinControllerProvider.notifier).changePin(
      currentPin: _currentController.text,
      newPin: _newController.text,
    );
    if (!mounted) return;
    final state = ref.read(pinControllerProvider);
    state.whenOrNull(
      data: (_) {
        AppFeedback.success(context, 'PIN updated successfully.');
        Navigator.of(context).maybePop();
      },
      error: (error, _) {
        AppFeedback.error(
          context,
          '$error'.replaceFirst('Exception: ', ''),
        );
      },
    );
  }

  Future<void> _onPinToggle(bool value) async {
    setState(() => _togglingPin = true);
    try {
      if (value) {
        final repository = ref.read(authRepositoryProvider);
        final hasPin = await repository.isPinSet();
        if (!hasPin) {
          if (!mounted) return;
          final pin = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const PinSetupDialog(),
          );
          if (pin == null || !mounted) {
            setState(() => _togglingPin = false);
            return;
          }
          await ref.read(pinControllerProvider.notifier).setPin(pin);
          if (!mounted) return;
          final pinState = ref.read(pinControllerProvider);
          if (pinState.hasError) {
            AppFeedback.error(
              context,
              '${pinState.error}'.replaceFirst('Exception: ', ''),
            );
            setState(() => _togglingPin = false);
            return;
          }
          _pinSet = true;
        }
        await ref.read(authProvider.notifier).setPinEnabled(true);
      } else {
        await ref.read(authProvider.notifier).setPinEnabled(false);
      }
    } finally {
      if (mounted) setState(() => _togglingPin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinControllerProvider);
    final authStateAsync = ref.watch(authProvider);

    if (_isLoading) {
      return const AppCard(
        tone: AppCardTone.muted,
        child: SizedBox(
          height: 320,
          child: Center(child: LoadingIndicator()),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            tone: AppCardTone.muted,
            padding: EdgeInsets.zero,
            child: SettingsRow(
              icon: Icons.pin_outlined,
              title: 'PIN Lock',
              subtitle: 'Use a 6-digit PIN to unlock',
              trailing: authStateAsync.when(
                data: (state) => Switch.adaptive(
                  value: state.pinEnabled,
                  onChanged: _togglingPin ? null : _onPinToggle,
                ),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
              isFirst: true,
              isLast: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            tone: AppCardTone.muted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset your secure access code',
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use exactly 6 digits. Your new PIN is stored only on this device.',
                  style: AppTypography.bodySm(context),
                ),
                const SizedBox(height: 24),
                if (_pinSet)
                  _PinField(
                    label: 'Current PIN',
                    controller: _currentController,
                    onChanged: () => setState(() {}),
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return 'Enter 6 digits';
                      }
                      return null;
                    },
                  ),
                if (_pinSet) const SizedBox(height: 20),
                _PinField(
                  label: 'New PIN',
                  controller: _newController,
                  onChanged: () => setState(() {}),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'Enter 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _PinField(
                  label: 'Confirm new PIN',
                  controller: _confirmController,
                  onChanged: () => setState(() {}),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'Enter 6 digits';
                    }
                    if (value != _newController.text) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppButton(
            label: 'Update PIN',
            fullWidth: true,
            loading: pinState.isLoading,
            onPressed: pinState.isLoading || !_fieldsValid ? null : _updatePin,
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatefulWidget {
  const _PinField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final FormFieldValidator<String>? validator;

  @override
  State<_PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<_PinField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AppTypography.body(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$length/6',
              style: AppTypography.bodySm(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}
