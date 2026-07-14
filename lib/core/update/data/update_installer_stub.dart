import 'package:beltech/core/update/domain/update_install_progress.dart';

Stream<UpdateInstallProgress> installApkUpdate(String url) async* {
  yield const UpdateInstallProgress(
    state: UpdateInstallState.unsupported,
    message: 'In-app APK updates are not supported on this platform.',
  );
}
