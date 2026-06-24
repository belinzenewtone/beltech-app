import 'package:beltech/core/update/domain/update_install_progress.dart';

import 'update_installer_stub.dart'
    if (dart.library.io) 'update_installer_io.dart' as installer;

Stream<UpdateInstallProgress> installApkUpdate(String url) {
  return installer.installApkUpdate(url);
}
