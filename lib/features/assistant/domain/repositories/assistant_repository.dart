import 'package:beltech/features/assistant/domain/entities/assistant_message.dart';

abstract class AssistantRepository {
  Stream<List<AssistantMessage>> watchConversation();
  List<AssistantSuggestion> suggestions();

  Future<void> sendMessage(String text);
  Future<void> clearConversation();
}
