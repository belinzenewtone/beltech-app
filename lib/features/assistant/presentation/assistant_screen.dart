import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:beltech/features/assistant/presentation/widgets/assistant_action_widgets.dart';
import 'package:beltech/features/assistant/presentation/widgets/assistant_conversation.dart';
import 'package:beltech/features/assistant/presentation/widgets/assistant_prompt_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final secondaryText = AppColors.textSecondaryFor(brightness);
    final messagesState = ref.watch(assistantMessagesProvider);
    final suggestions = ref.watch(assistantSuggestionsProvider);
    final writeState = ref.watch(assistantWriteControllerProvider);
    final conversationState = ref.watch(
      assistantConversationControllerProvider,
    );

    ref.listen<AsyncValue<void>>(assistantWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(context, 'Message failed to send.', ref: ref);
      }
    });
    ref.listen<AsyncValue<void>>(assistantConversationControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(context, 'Unable to clear chat history.', ref: ref);
      } else if (previous?.isLoading == true && next.hasValue) {
        AppFeedback.success(context, 'Chat history cleared.', ref: ref);
      }
    });

    final hasMessages = messagesState.valueOrNull?.isNotEmpty ?? false;

    // bottomPadding: 0 lets the composer sit flush just above the tab bar.
    // PageShell's non-scrollable branch will add safeBottom automatically.
    return PageShell(
      scrollable: false,
      horizontalPadding: AppSpacing.md,
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Assistant',
            action: AssistantPillButton(
              icon: Icons.add_rounded,
              label: 'New chat',
              onTap: hasMessages && !conversationState.isLoading
                  ? _confirmClearChats
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                0,
                0,
                0,
                AppSpacing.sectionGap,
              ),
              children: [
                // Quick prompt suggestions — horizontal scroll row
                AssistantPromptGrid(
                  prompts: suggestions.map((item) => item.prompt).toList(),
                  onPromptTap: _sendMessage,
                ),
                const SizedBox(height: 14),
                messagesState.when(
                  data: (messages) => messages.isEmpty
                      ? const AssistantEmptyState()
                      : AssistantConversationList(messages: messages),
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (_, __) => ErrorMessage(
                    label: 'Unable to load assistant',
                    onRetry: () => ref.invalidate(assistantMessagesProvider),
                  ),
                ),
              ],
            ),
          ),
          // ── Composer sits directly above the floating tab bar ────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            child: AppCard(
              tone: AppCardTone.muted,
              borderRadius: AppRadius.full,
              padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(_messageController.text),
                      style: AppTypography.body(context),
                      decoration: InputDecoration(
                        hintText: 'Ask anything…',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        hintStyle: AppTypography.body(
                          context,
                        ).copyWith(color: secondaryText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AssistantSendButton(
                    loading: writeState.isLoading,
                    onTap: () => _sendMessage(_messageController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final payload = text.trim();
    if (payload.isEmpty) {
      return;
    }
    _messageController.clear();
    await ref
        .read(assistantWriteControllerProvider.notifier)
        .sendMessage(payload);
  }

  Future<void> _confirmClearChats() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear chats', style: AppTypography.sectionTitle(context)),
        content: Text(
          'This will remove previous assistant messages.',
          style: AppTypography.bodyMd(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Clear',
            onPressed: () => Navigator.of(context).pop(true),
            variant: AppButtonVariant.danger,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
    if (shouldClear != true || !mounted) {
      return;
    }
    await ref
        .read(assistantConversationControllerProvider.notifier)
        .clearConversation();
  }
}
