import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Thin wrapper around [ShorebirdUpdater] so the rest of the app
/// has no direct dependency on the third-party package.
///
/// The native auto-updater (auto_update: true in shorebird.yaml) is
/// responsible for *downloading* patches — this service only queries
/// the *state* of that download so the app can prompt the user to restart.
class ShorebirdPatchService {
  ShorebirdPatchService() : _updater = ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  /// Whether the Shorebird updater is compiled into this build.
  /// Returns false for debug builds and non-Shorebird releases.
  Future<bool> isShorebirdAvailable() async => _updater.isAvailable;

  /// True when the native auto-updater has downloaded a new patch and
  /// a cold restart of the app will apply it.
  ///
  /// This does NOT download anything — downloading is handled automatically
  /// by the Shorebird runtime (auto_update: true in shorebird.yaml).
  Future<bool> isRestartRequired() async {
    final current = await _updater.readCurrentPatch();
    final next = await _updater.readNextPatch();
    return next != null && next != current;
  }

  /// The patch number currently running in this session (null = base release).
  Future<int?> currentPatch() async {
    final patch = await _updater.readCurrentPatch();
    return patch?.number;
  }

  /// The patch number scheduled to run on next launch, if one is downloaded.
  Future<int?> nextPatch() async {
    final patch = await _updater.readNextPatch();
    return patch?.number;
  }
}
