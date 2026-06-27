class AuthState {
  const AuthState({
    required this.biometricSupported,
    required this.biometricEnabled,
    required this.isAuthenticating,
    this.errorMessage,
    this.pinEnabled = false,
  });

  final bool biometricSupported;
  final bool biometricEnabled;
  final bool isAuthenticating;
  final String? errorMessage;
  final bool pinEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          biometricSupported == other.biometricSupported &&
          biometricEnabled == other.biometricEnabled &&
          isAuthenticating == other.isAuthenticating &&
          errorMessage == other.errorMessage &&
          pinEnabled == other.pinEnabled;

  @override
  int get hashCode => Object.hash(
    biometricSupported,
    biometricEnabled,
    isAuthenticating,
    errorMessage,
    pinEnabled,
  );

  AuthState copyWith({
    bool? biometricSupported,
    bool? biometricEnabled,
    bool? isAuthenticating,
    String? errorMessage,
    bool? pinEnabled,
  }) {
    return AuthState(
      biometricSupported: biometricSupported ?? this.biometricSupported,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      errorMessage: errorMessage,
      pinEnabled: pinEnabled ?? this.pinEnabled,
    );
  }

  static const AuthState initial = AuthState(
    biometricSupported: false,
    biometricEnabled: false,
    isAuthenticating: false,
    errorMessage: null,
    pinEnabled: false,
  );
}
