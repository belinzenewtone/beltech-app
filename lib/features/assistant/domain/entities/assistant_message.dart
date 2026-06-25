class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          isUser == other.isUser &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, text, isUser, createdAt);
}

class AssistantSuggestion {
  const AssistantSuggestion(this.prompt);

  final String prompt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantSuggestion &&
          runtimeType == other.runtimeType &&
          prompt == other.prompt;

  @override
  int get hashCode => prompt.hashCode;
}
