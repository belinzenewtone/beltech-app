import 'dart:async';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/update/data/app_update_service.dart';
import 'package:beltech/core/update/domain/app_update_info.dart';
import 'package:beltech/core/update/domain/update_install_progress.dart';
import 'package:flutter/material.dart';

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    super.key,
    required this.update,
    required this.service,
  });

  final AppUpdateInfo update;
  final AppUpdateService service;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  StreamSubscription<UpdateInstallProgress>? _installSub;
  bool _installing = false;
  double? _progress;
  String? _statusLabel;
  String? _errorLabel;

  @override
  void dispose() {
    _installSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: !widget.update.forceUpdate && !_installing,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.system_update,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child:
                        Text(widget.update.title, style: textTheme.titleMedium),
                  ),
                  if (!widget.update.forceUpdate && !_installing)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.update.message,
                style: textTheme.bodyLarge,
              ),
              if (widget.update.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...widget.update.notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $note', style: textTheme.bodyMedium),
                  ),
                ),
              ],
              if (_installing || _progress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: _progress,
                    backgroundColor: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusLabel ?? _percentLabel(_progress),
                  style: textTheme.bodySmall,
                ),
              ],
              if (_errorLabel != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorLabel!,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (!widget.update.forceUpdate)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _installing
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  if (!widget.update.forceUpdate) const SizedBox(width: 10),
                  if (widget.update.hasWebsiteUrl)
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _installing
                            ? null
                            : () => _openWebsite(closeDialog: false),
                        child: const Text('Website'),
                      ),
                    ),
                  if (widget.update.hasWebsiteUrl) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _installing ? null : _startUpdate,
                      child: Text(_installing ? 'Updating...' : 'Update Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startUpdate() async {
    setState(() {
      _errorLabel = null;
    });

    if (!widget.update.hasApkUrl) {
      await _openWebsite(closeDialog: true);
      return;
    }

    setState(() {
      _installing = true;
      _progress = null;
      _statusLabel = 'Starting update...';
    });

    await _installSub?.cancel();
    _installSub = widget.service.installAndroidUpdate(widget.update).listen(
      (progress) async {
        if (!mounted) {
          return;
        }
        setState(() {
          _progress = progress.percent;
          _statusLabel = progress.message ?? _stateMessage(progress.state);
        });

        if (progress.state == UpdateInstallState.failed ||
            progress.state == UpdateInstallState.unsupported) {
          setState(() {
            _installing = false;
            _errorLabel =
                progress.message ?? 'Auto-install failed. Use Website instead.';
          });
        }
        if (progress.state == UpdateInstallState.completed) {
          if (!mounted) {
            return;
          }
          Navigator.of(context).pop();
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _installing = false;
          _errorLabel = '$error';
        });
      },
      onDone: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _installing = false;
        });
      },
    );
  }

  Future<void> _openWebsite({required bool closeDialog}) async {
    final opened = await widget.service.openUpdateWebsite(widget.update);
    if (!mounted) {
      return;
    }
    if (!opened) {
      setState(() {
        _errorLabel = 'No valid update website URL configured.';
      });
      return;
    }
    if (closeDialog) {
      Navigator.of(context).pop();
    }
  }

  String _percentLabel(double? progress) {
    if (progress == null) {
      return 'Preparing update...';
    }
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  String _stateMessage(UpdateInstallState state) {
    return switch (state) {
      UpdateInstallState.starting => 'Starting update...',
      UpdateInstallState.downloading => 'Downloading update...',
      UpdateInstallState.installing => 'Installing update...',
      UpdateInstallState.completed => 'Update installed',
      UpdateInstallState.failed => 'Update failed',
      UpdateInstallState.unsupported => 'Update not supported on this device',
    };
  }
}
