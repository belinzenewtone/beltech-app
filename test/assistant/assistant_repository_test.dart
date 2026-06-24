import 'package:beltech/data/local/drift/assistant_profile_store.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AssistantProfileStore store;
  late AppDriftStore appStore;
  late AssistantRepositoryImpl repository;

  setUp(() {
    store = AssistantProfileStore();
    appStore = AppDriftStore();
    repository = AssistantRepositoryImpl(store, appStore);
  });

  tearDown(() async {
    await store.dispose();
    await appStore.dispose();
  });

  test('sendMessage appends user and assistant response', () async {
    final initial = await repository.watchConversation().first;
    final nextConversation = repository.watchConversation().firstWhere(
          (messages) => messages.length >= initial.length + 2,
        );

    await repository.sendMessage('How much did I spend today?');

    final updated = await nextConversation.timeout(const Duration(seconds: 2));
    expect(updated.length, initial.length + 2);
    expect(updated[updated.length - 2].isUser, isTrue);
    expect(updated.last.isUser, isFalse);
    expect(updated.last.text.toLowerCase(), contains('spending'));
  });

  test('suggestions return expected prompts', () {
    final suggestions = repository.suggestions();
    expect(suggestions, isNotEmpty);
    expect(suggestions.first.prompt.toLowerCase(), contains('spend'));
  });
}
