class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSinceLabel,
    required this.verified,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String phone;
  final String memberSinceLabel;
  final bool verified;
  final String? avatarUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          memberSinceLabel == other.memberSinceLabel &&
          verified == other.verified &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      Object.hash(name, email, phone, memberSinceLabel, verified, avatarUrl);
}
