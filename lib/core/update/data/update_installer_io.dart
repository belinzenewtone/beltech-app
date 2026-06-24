import 'dart:io';

import 'package:beltech/core/update/domain/update_install_progress.dart';

Stream<UpdateInstallProgress> installApkUpdate(String url) async* {
  final platformHint = Platform.isAndroid
      ? 'Shorebird patches are applied on next app start.'
      : 'Restart the app to apply downloaded patch updates.';
  yield UpdateInstallProgress(
    state: UpdateInstallState.unsupported,
    message: 'In-app APK installer is disabled for Shorebird builds. '
        '$platformHint',
  );
}
