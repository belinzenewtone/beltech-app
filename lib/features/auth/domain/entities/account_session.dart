class AccountSession {
  const AccountSession({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.displayName,
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountSession &&
          runtimeType == other.runtimeType &&
          isAuthenticated == other.isAuthenticated &&
          userId == other.userId &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(isAuthenticated, userId, email, displayName);

  static const AccountSession unauthenticated = AccountSession(
    isAuthenticated: false,
  );
}
