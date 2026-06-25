class DriftProfileRecord {
  const DriftProfileRecord({
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
}

class DriftAssistantMessageRecord {
  const DriftAssistantMessageRecord({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
}
