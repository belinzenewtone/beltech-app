import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/assistant/domain/entities/assistant_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AssistantConversationList extends StatelessWidget {
  const AssistantConversationList({required this.messages, super.key});

  final List<AssistantMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: messages
          .map(
            (message) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AssistantMessageBubble(message: message),
            ),
          )
          .toList(),
    );
  }
}

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({required this.message, super.key});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final timeLabel = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(message.createdAt));
    final screenWidth = MediaQuery.of(context).size.width;
    final timestampStyle = AppTypography.metaText(context).copyWith(
      fontSize: 11,
      color: message.isUser
          ? Colors.white.withValues(alpha: 0.65)
          : AppColors.textMutedFor(brightness),
    );

    if (message.isUser) {
      return Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  message.text.trim(),
                  style: AppTypography.body(
                    context,
                  ).copyWith(color: Colors.white, height: 1.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(timeLabel, style: timestampStyle),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCard(
              tone: AppCardTone.muted,
              borderRadius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: MarkdownBody(
                data: message.text.trim(),
                selectable: false,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.body(
                    context,
                  ).copyWith(color: onSurface, height: 1.35),
                  strong: AppTypography.body(
                    context,
                  ).copyWith(color: onSurface, fontWeight: FontWeight.w700),
                  listBullet: TextStyle(color: onSurface),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(timeLabel, style: timestampStyle),
          ],
        ),
      ),
    );
  }
}

class AssistantEmptyState extends StatelessWidget {
  const AssistantEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What can I help with?',
            style: AppTypography.headlineSm(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Ask about spending, tasks, or schedule.',
            style: AppTypography.bodySm(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
