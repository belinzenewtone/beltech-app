import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/assistant/domain/entities/assistant_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _assistantIntroMessage =
    "Hey! I'm your BELTECH assistant. Ask me about spending, tasks, or schedule.";

final assistantMessagesProvider = StreamProvider<List<AssistantMessage>>(
  (ref) => ref
      .watch(assistantRepositoryProvider)
      .watchConversation()
      .map(_normalizeConversation),
);

final assistantSuggestionsProvider = Provider<List<AssistantSuggestion>>(
  (ref) => ref.watch(assistantRepositoryProvider).suggestions(),
);

class AssistantWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> sendMessage(String text) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(assistantRepositoryProvider).sendMessage(text);
    });
  }
}

final assistantWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<AssistantWriteController, void>(
  AssistantWriteController.new,
);

class AssistantConversationController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> clearConversation() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(assistantRepositoryProvider).clearConversation();
    });
  }
}

final assistantConversationControllerProvider =
    AutoDisposeAsyncNotifierProvider<AssistantConversationController, void>(
  AssistantConversationController.new,
);

List<AssistantMessage> _normalizeConversation(
  List<AssistantMessage> messages,
) {
  final ordered = [...messages]..sort((left, right) {
      final byTime = left.createdAt.compareTo(right.createdAt);
      if (byTime != 0) {
        return byTime;
      }
      return left.id.compareTo(right.id);
    });

  var introSeen = false;
  final normalized = <AssistantMessage>[];
  for (final message in ordered) {
    final normalizedText = message.text.trim().toLowerCase();
    final isIntro = !message.isUser &&
        (normalizedText == _assistantIntroMessage.toLowerCase() ||
            normalizedText.startsWith("hey! i'm your beltech assistant."));
    if (isIntro) {
      if (introSeen) {
        continue;
      }
      introSeen = true;
    }
    normalized.add(message);
  }
  return normalized;
}
