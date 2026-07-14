import 'dart:async';

import 'package:beltech/core/di/update_providers.dart';
import 'package:beltech/core/ota/patch_notes_registry.dart';
import 'package:beltech/core/ota/patch_ready_info.dart';
import 'package:beltech/core/ota/shorebird_patch_service.dart';
import 'package:beltech/core/ota/shorebird_providers.dart';
import 'package:beltech/core/update/domain/app_update_info.dart';
import 'package:beltech/core/update/presentation/patch_ready_dialog.dart';
import 'package:beltech/core/update/presentation/update_prompt_widget.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GlobalUpdateHost extends ConsumerStatefulWidget {
  const GlobalUpdateHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalUpdateHost> createState() => _GlobalUpdateHostState();
}

class _GlobalUpdateHostState extends ConsumerState<GlobalUpdateHost>
    with WidgetsBindingObserver {
  bool _checkedBinaryUpdate = false;
  bool _patchDialogOpen = false;
  int? _dismissedPatchForSession;
  bool _updatePromptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runStartupChecks());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkShorebirdPatch(includeDelayedCheck: false));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _runStartupChecks() async {
    await _checkForBinaryUpdate();
    await _checkShorebirdPatch(includeDelayedCheck: true);
  }

  Future<void> _checkForBinaryUpdate() async {
    if (_checkedBinaryUpdate || !mounted) return;
    _checkedBinaryUpdate = true;

    final stateMachine = ref.read(updateStateMachineProvider);
    final repository = ref.read(updateRepositoryProvider);
    final service = ref.read(appUpdateServiceProvider);

    stateMachine.checkForUpdate();

    try {
      final update = await service.fetchAvailableUpdate();
      if (!mounted || update == null) {
        stateMachine.reset();
        return;
      }

      stateMachine.updateAvailable(update);

      final currentVersion = await _currentVersion();
      if (!mounted) return;

      final row = await repository.fetchActiveUpdateRow();
      if (!mounted) return;
      if (row != null &&
          _asString(row['current_version']) == update.latestVersion) {
        return;
      }

      await repository.saveUpdate(
        platform: 'android',
        currentVersion: update.latestVersion,
        minimumSupportedVersion: update.minSupportedVersion.isNotEmpty
            ? update.minSupportedVersion
            : null,
        storeUrl: update.apkUrl ?? update.websiteUrl,
        changelog: update.notes.join('||'),
        isForce: update.forceUpdate,
      );
      if (!mounted) return;

      if (_updatePromptOpen) return;
      _updatePromptOpen = true;

      await showUpdatePromptSheet(
        context: context,
        update: update,
        currentVersion: currentVersion,
        onUpdateNow: () {
          stateMachine.startDownload();
          _openStoreOrWebsite(update);
          stateMachine.downloadComplete();
          _updatePromptOpen = false;
        },
        onLater: () {
          stateMachine.reset();
          _updatePromptOpen = false;
        },
      );

      _updatePromptOpen = false;
    } catch (_) {
      stateMachine.reset();
    }
  }

  Future<void> _openStoreOrWebsite(AppUpdateInfo update) async {
    final service = ref.read(appUpdateServiceProvider);
    if (update.apkUrl != null && update.apkUrl!.isNotEmpty) {
      unawaited(service.installAndroidUpdate(update).drain());
      return;
    }
    if (update.websiteUrl != null && update.websiteUrl!.isNotEmpty) {
      unawaited(service.openUpdateWebsite(update));
    }
  }

  Future<String> _currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.0.0';
    }
  }

  String _asString(Object? value) => (value ?? '').toString().trim();

  Future<void> _checkShorebirdPatch({required bool includeDelayedCheck}) async {
    if (!mounted) return;

    final service = ref.read(shorebirdPatchServiceProvider);
    try {
      final available = await service.isShorebirdAvailable();
      if (!available || !mounted) return;

      final immediateInfo = await _pendingPatchInfo(service);
      if (!mounted) return;
      if (immediateInfo != null) {
        await _showPatchDialogIfNeeded(immediateInfo);
        return;
      }

      if (!includeDelayedCheck) return;

      await Future<void>.delayed(const Duration(seconds: 8));
      if (!mounted) return;

      final delayedInfo = await _pendingPatchInfo(service);
      if (!mounted || delayedInfo == null) return;
      await _showPatchDialogIfNeeded(delayedInfo);
    } catch (_) {
      return;
    }
  }

  Future<PatchReadyInfo?> _pendingPatchInfo(
    ShorebirdPatchService service,
  ) async {
    final currentPatchNumber = await service.currentPatch();
    final nextPatchNumber = await service.nextPatch();
    if (nextPatchNumber == null || nextPatchNumber == currentPatchNumber) {
      return null;
    }
    return patchReadyInfoFor(
      currentPatchNumber: currentPatchNumber,
      nextPatchNumber: nextPatchNumber,
    );
  }

  Future<void> _showPatchDialogIfNeeded(PatchReadyInfo info) async {
    if (!mounted ||
        _patchDialogOpen ||
        _dismissedPatchForSession == info.nextPatchNumber) {
      return;
    }

    _patchDialogOpen = true;
    await showAppDialog<void>(
      context: context,
      builder: (_) => PatchReadyDialog(
        info: info,
        onDismiss: () {
          _dismissedPatchForSession = info.nextPatchNumber;
          Navigator.of(context, rootNavigator: true).maybePop();
        },
      ),
    );
    _patchDialogOpen = false;
  }
}
