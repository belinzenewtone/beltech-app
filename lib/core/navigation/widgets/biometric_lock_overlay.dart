import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class BiometricLockOverlay extends StatefulWidget {
  const BiometricLockOverlay({
    super.key,
    required this.busy,
    required this.message,
    required this.onUnlock,
    this.showPinFallback = true,
    this.pinError,
    this.onPinSubmit,
  });

  final bool busy;
  final String? message;
  final Future<void> Function() onUnlock;
  final bool showPinFallback;
  final String? pinError;
  final Future<void> Function(String pin)? onPinSubmit;

  @override
  State<BiometricLockOverlay> createState() => _BiometricLockOverlayState();
}

class _BiometricLockOverlayState extends State<BiometricLockOverlay> {
  final _pinCtrl = TextEditingController();
  bool _showPinField = false;
  bool _pinBusy = false;
  String? _localPinError;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BiometricLockOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pinError != oldWidget.pinError) {
      setState(() {
        _localPinError = widget.pinError;
      });
    }
  }

  Future<void> _onPinSubmit(String pin) async {
    if (pin.trim().isEmpty || _pinBusy) return;
    setState(() {
      _pinBusy = true;
      _localPinError = null;
    });
    try {
      await widget.onPinSubmit?.call(pin.trim());
    } finally {
      if (mounted) {
        setState(() {
          _pinBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.background.withValues(alpha: 0.8),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      color: AppColors.accent,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unlock BELTECH',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showPinField
                          ? 'Enter your PIN to unlock.'
                          : 'Use your fingerprint or face to continue.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (widget.message != null && !_showPinField) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.message!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_showPinField)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _pinCtrl,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          enabled: !_pinBusy,
                          decoration: InputDecoration(
                            labelText: 'Enter PIN',
                            errorText: _localPinError,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          onSubmitted: _onPinSubmit,
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: widget.busy
                              ? null
                              : () => widget.onUnlock(),
                          icon: widget.busy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_open_rounded),
                          label: Text(
                            widget.busy ? 'Authenticating...' : 'Unlock',
                          ),
                        ),
                      ),
                    if (_showPinField) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _pinBusy
                              ? null
                              : () => _onPinSubmit(_pinCtrl.text),
                          icon: _pinBusy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_open_rounded),
                          label: Text(
                            _pinBusy ? 'Verifying...' : 'Unlock with PIN',
                          ),
                        ),
                      ),
                    ],
                    if (widget.showPinFallback) ...[
                      const SizedBox(height: 8),
                      if (_showPinField)
                        TextButton(
                          onPressed: _pinBusy
                              ? null
                              : () => setState(() {
                                  _showPinField = false;
                                  _pinCtrl.clear();
                                  _localPinError = null;
                                }),
                          child: const Text('Use fingerprint instead'),
                        )
                      else
                        TextButton(
                          onPressed: () => setState(() {
                            _showPinField = true;
                            _localPinError = null;
                          }),
                          child: const Text('Use PIN instead'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
