enum UpdateInstallState {
  starting,
  downloading,
  installing,
  completed,
  failed,
  unsupported,
}

class UpdateInstallProgress {
  const UpdateInstallProgress({
    required this.state,
    this.percent,
    this.message,
  });

  final UpdateInstallState state;
  final double? percent;
  final String? message;
}
