import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_icon_pill_button.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/providers/global_search_providers.dart';
import 'package:intl/intl.dart';
import 'package:beltech/features/recurring/presentation/providers/recurring_providers.dart';
import 'package:beltech/features/recurring/presentation/widgets/recurring_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'recurring_screen_row.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesState = ref.watch(recurringTemplatesProvider);
    final writeState = ref.watch(recurringWriteControllerProvider);

    ref.listen<AsyncValue<void>>(recurringWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(
          context,
          'Recurring action failed. Please try again.',
        );
      }
    });

    return SecondaryPageShell(
      title: 'Recurring',

      actions: [
        AppIconPillButton(
          icon: Icons.add_rounded,
          label: 'Add',
          tone: AppIconPillTone.accent,
          onPressed: writeState.isLoading
              ? null
              : () async {
                  final input = await showRecurringTemplateDialog(context);
                  if (input == null) return;
                  await ref
                      .read(recurringWriteControllerProvider.notifier)
                      .addTemplate(
                        kind: input.kind,
                        title: input.title,
                        description: input.description,
                        category: input.category,
                        amountKes: input.amountKes,
                        priority: input.priority,
                        cadence: input.cadence,
                        nextRunAt: input.nextRunAt,
                      );
                  if (context.mounted &&
                      !ref.read(recurringWriteControllerProvider).hasError) {
                    AppFeedback.success(context, 'Template added');
                  }
                },
        ),
        AppIconPillButton(
          icon: Icons.play_arrow_rounded,
          label: 'Run',
          tone: AppIconPillTone.subtle,
          onPressed: writeState.isLoading
              ? null
              : () async {
                  AppHaptics.lightImpact();
                  final count = await ref
                      .read(recurringWriteControllerProvider.notifier)
                      .materializeNow();
                  if (context.mounted) {
                    AppFeedback.info(context, 'Generated $count item(s).');
                  }
                },
        ),
      ],
      child: templatesState.when(
        data: (templates) {
          _consumeSearchTarget(context, ref, templates);
          if (templates.isEmpty) {
            return const AppEmptyState(
              icon: Icons.repeat_rounded,
              title: 'No recurring items',
              subtitle:
                  'Templates auto-generate tasks and expenses at specified intervals',
            );
          }
          return Column(
            children: List.generate(templates.length, (index) {
              final template = templates[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < templates.length - 1 ? AppSpacing.listGap : 0,
                ),
                child: _RecurringRow(
                  template: template,
                  busy: writeState.isLoading,
                  onEdit: () async {
                    await _editTemplate(context, ref, template);
                  },
                  onDelete: () async {
                    final confirmed = await showDeleteConfirmDialog(
                      context,
                      title: 'Delete template',
                      body:
                          'Remove "${template.title}"? Future auto-generated items will stop.',
                    );
                    if (confirmed != true || !context.mounted) return;
                    await ref
                        .read(recurringWriteControllerProvider.notifier)
                        .deleteTemplate(template.id);
                    if (context.mounted &&
                        !ref.read(recurringWriteControllerProvider).hasError) {
                      AppFeedback.success(context, 'Template deleted');
                    }
                  },
                  onToggleEnabled: () async {
                    await ref
                        .read(recurringWriteControllerProvider.notifier)
                        .toggleEnabled(template);
                    if (context.mounted &&
                        !ref.read(recurringWriteControllerProvider).hasError) {
                      AppFeedback.info(
                        context,
                        template.enabled
                            ? 'Template paused'
                            : 'Template resumed',
                      );
                    }
                  },
                ),
              );
            }),
          );
        },
        loading: () => Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index < 3 ? AppSpacing.listGap : 0,
              ),
              child: AppSkeleton.card(context, height: 100),
            ),
          ),
        ),
        error: (_, __) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load templates',
          subtitle: 'Please try again',
          action: TextButton(
            onPressed: () => ref.invalidate(recurringTemplatesProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }

  void _consumeSearchTarget(
    BuildContext context,
    WidgetRef ref,
    List<RecurringTemplate> templates,
  ) {
    final pendingTarget = ref.read(globalSearchDeepLinkTargetProvider);
    if (pendingTarget?.kind != GlobalSearchKind.recurring) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() async {
        if (!context.mounted) {
          return;
        }
        final target = ref.read(globalSearchDeepLinkTargetProvider);
        if (target?.kind != GlobalSearchKind.recurring) {
          return;
        }
        ref.read(globalSearchDeepLinkTargetProvider.notifier).state = null;

        final recordId = target?.recordId;
        if (recordId == null) {
          return;
        }
        final template =
            templates.where((item) => item.id == recordId).firstOrNull;
        if (template == null) {
          AppFeedback.info(
            context,
            'This recurring template no longer exists.',
          );
          return;
        }

        await _editTemplate(context, ref, template);
      });
    });
  }

  Future<void> _editTemplate(
    BuildContext context,
    WidgetRef ref,
    RecurringTemplate template,
  ) async {
    final input = await showRecurringTemplateDialog(context, initial: template);
    if (input == null) {
      return;
    }
    await ref.read(recurringWriteControllerProvider.notifier).updateTemplate(
          templateId: template.id,
          kind: input.kind,
          title: input.title,
          description: input.description,
          category: input.category,
          amountKes: input.amountKes,
          priority: input.priority,
          cadence: input.cadence,
          nextRunAt: input.nextRunAt,
          enabled: template.enabled,
        );
    if (context.mounted &&
        !ref.read(recurringWriteControllerProvider).hasError) {
      AppFeedback.success(context, 'Template updated');
    }
  }
}
