import 'package:beltech/core/ota/shorebird_patch_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton service for querying Shorebird patch state.
final shorebirdPatchServiceProvider = Provider<ShorebirdPatchService>(
  (_) => ShorebirdPatchService(),
);

/// True when the native auto-updater has a patch ready and the user
/// needs to restart the app to apply it.
///
/// AppShell writes this value after checking [ShorebirdPatchService].
/// [PatchReadyBanner] reads it to decide whether to show.
final patchRestartRequiredProvider = StateProvider<bool>((_) => false);
