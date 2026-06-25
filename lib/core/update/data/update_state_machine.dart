import 'package:beltech/core/update/domain/app_update_info.dart';

class UpdateStateMachine {
  UpdateState _state = UpdateState.idle;
  AppUpdateInfo? _availableUpdate;

  UpdateState get state => _state;
  AppUpdateInfo? get availableUpdate => _availableUpdate;

  void checkForUpdate() {
    _state = UpdateState.checking;
  }

  void updateAvailable(AppUpdateInfo info) {
    _availableUpdate = info;
    _state = UpdateState.available;
  }

  void startDownload() {
    _state = UpdateState.downloading;
  }

  void downloadComplete() {
    _state = UpdateState.ready;
  }

  void markInstalled() {
    _state = UpdateState.installed;
  }

  void reset() {
    _state = UpdateState.idle;
    _availableUpdate = null;
  }
}
