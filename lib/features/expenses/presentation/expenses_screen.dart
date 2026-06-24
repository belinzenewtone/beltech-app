import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_fab.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_icon_pill_button.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/expenses_screen_helpers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expense_dialogs.dart';
import 'package:beltech/features/expenses/presentation/widgets/expenses_snapshot_content.dart';
import 'package:beltech/features/expenses/presentation/widgets/import_health_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotState = ref.watch(expensesSnapshotProvider);
    final selectedFilter = ref.watch(expenseFilterProvider);
    // select() narrows rebuild scope: only rebuild this screen when isLoading
    // actually flips — not on every intermediate writeState emission.
    final writeBusy = ref.watch(
      expenseWriteControllerProvider.select((s) => s.isLoading),
    );
    final importMetricsState = ref.watch(expenseImportMetricsProvider);
    final reviewQueueState = ref.watch(expenseReviewQueueProvider);
    final quarantineState = ref.watch(expenseQuarantineQueueProvider);
    final paybillProfilesState = ref.watch(expensePaybillProfilesProvider);
    final fulizaLifecycleState = ref.watch(expenseFulizaLifecycleProvider);
    final contentSwitchDuration = AppMotion.duration(
      context,
      normalMs: 180,
      reducedMs: 0,
    );
    final snapshotChild = snapshotState.when(
      data: (snapshot) {
        consumeExpenseSearchTarget(context, ref, snapshot);
        return KeyedSubtree(
          key: const ValueKey<String>('expenses-data'),
          child: ExpensesSnapshotContent(
            snapshot: snapshot,
            selectedFilter: selectedFilter,
            busy: writeBusy,
            onFilterChanged: (filter) {
              ref.read(expenseFilterProvider.notifier).state = filter;
            },
            onEditExpense: (expense) async {
              await editExpenseEntry(context, ref, expense);
            },
            onMerchantTap: (expense) {
              context.pushNamed('merchant-detail', extra: expense.title);
            },
            onDeleteExpense: (expense) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .deleteExpense(expense.id);
              if (!context.mounted) return;
              if (ref.read(expenseWriteControllerProvider).hasError) return;
              // Undo snackbar
              final messenger = ScaffoldMessenger.maybeOf(context);
              if (messenger == null) return;
              messenger.hideCurrentSnackBar();
              final keyboardInset =
                  MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0;
              final closed = await messenger
                  .showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Transaction deleted',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      action: SnackBarAction(label: 'Undo', onPressed: () {}),
                      behavior: SnackBarBehavior.floating,
                      margin:
                          EdgeInsets.fromLTRB(16, 0, 16, 88 + keyboardInset),
                      duration: const Duration(seconds: 4),
                    ),
                  )
                  .closed;
              if (closed == SnackBarClosedReason.action && context.mounted) {
                await ref
                    .read(expenseWriteControllerProvider.notifier)
                    .addExpense(
                      title: expense.title,
                      category: expense.category,
                      amountKes: expense.amountKes,
                      occurredAt: expense.occurredAt,
                    );
              }
            },
            importMetrics: importMetricsState.valueOrNull ??
                const ExpenseImportMetrics(
                  reviewQueueCount: 0,
                  quarantineCount: 0,
                  retryQueueCount: 0,
                  failedQueueCount: 0,
                ),
            reviewItems: reviewQueueState.valueOrNull ?? const [],
            quarantineItems: quarantineState.valueOrNull ?? const [],
            paybillProfiles:
                paybillProfilesState.valueOrNull ?? const <PaybillProfile>[],
            fulizaEvents: fulizaLifecycleState.valueOrNull ??
                const <FulizaLifecycleEvent>[],
            onApproveReview: (item) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .approveReviewItem(item.id);
              if (context.mounted &&
                  !ref.read(expenseWriteControllerProvider).hasError) {
                AppFeedback.success(context, 'Review item approved', ref: ref);
              }
            },
            onRejectReview: (item) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .rejectReviewItem(item.id);
              if (context.mounted &&
                  !ref.read(expenseWriteControllerProvider).hasError) {
                AppFeedback.info(context, 'Review item rejected', ref: ref);
              }
            },
            onDismissQuarantine: (item) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .dismissQuarantineItem(item.id);
              if (context.mounted &&
                  !ref.read(expenseWriteControllerProvider).hasError) {
                AppFeedback.info(
                  context,
                  'Quarantine item dismissed',
                  ref: ref,
                );
              }
            },
            onReplayImportQueue: () async {
              await replayExpenseImportQueue(context, ref);
            },
          ),
        );
      },
      loading: () => const KeyedSubtree(
        key: ValueKey<String>('expenses-loading'),
        child: FinanceSkeletonList(),
      ),
      error: (_, __) => KeyedSubtree(
        key: const ValueKey<String>('expenses-error'),
        child: ErrorMessage(
          label: 'Unable to load expenses',
          onRetry: () => ref.invalidate(expensesSnapshotProvider),
        ),
      ),
    );
    ref.listen<AsyncValue<void>>(expenseWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(
          context,
          'Unable to save transaction. Please try again.',
          ref: ref,
        );
      }
    });
    // Resolve import metrics for the health banner (safe fallback to zeros).
    final importMetrics = ref.watch(expenseImportMetricsProvider).valueOrNull ??
        const ExpenseImportMetrics(
          reviewQueueCount: 0,
          quarantineCount: 0,
          retryQueueCount: 0,
          failedQueueCount: 0,
        );

    return Stack(
      children: [
        // horizontalPadding: 0 so the ImportHealthBanner can bleed edge-to-edge.
        // Each child that needs horizontal padding applies it directly.
        PageShell(
          scrollable: false,
          topPadding: 0, // banner sits above the page title
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Import Health Banner (RN-style full-width top strip) ────────
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: -AppSpacing.screenHorizontal,
                ),
                child: ImportHealthBanner(
                  metrics: importMetrics,
                  onTap: () => context.pushNamed('import-health'),
                ),
              ),
              const SizedBox(height: AppSpacing.screenTop),
              PageHeader(
                title: 'Finance',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconPillButton(
                      icon: Icons.label_outline_rounded,
                      label: 'Categorize',
                      tone: AppIconPillTone.subtle,
                      onPressed: writeBusy
                          ? null
                          : () => context.pushNamed('categorize'),
                    ),
                    const SizedBox(width: 8),
                    AppIconPillButton(
                      icon: Icons.upload_file_rounded,
                      label: 'Export',
                      tone: AppIconPillTone.subtle,
                      onPressed: writeBusy
                          ? null
                          : () => context.pushNamed('export'),
                    ),
                    const SizedBox(width: 8),
                    AppIconPillButton(
                      icon: Icons.phone_android_rounded,
                      label: 'Import',
                      tone: AppIconPillTone.subtle,
                      onPressed: writeBusy
                          ? null
                          : () => handleExpenseSmsImport(context, ref),
                    ),
                  ],
                ),
              ),
              const _DataFreshPill(),
              const SizedBox(height: AppSpacing.listGap),
              Expanded(
                child: AnimatedSwitcher(
                  duration: contentSwitchDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: snapshotChild,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: AppSpacing.fabBottom(context),
          child: AppFab(
            busy: writeBusy,
            onPressed: () async {
              final input = await showAddExpenseDialog(context);
              if (input == null) return;
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .addExpense(
                    title: input.title,
                    category: input.category,
                    amountKes: input.amountKes,
                    occurredAt: input.occurredAt,
                  );
              if (context.mounted &&
                  !ref.read(expenseWriteControllerProvider).hasError) {
                AppFeedback.success(context, 'Transaction added', ref: ref);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── Data-fresh indicator ──────────────────────────────────────────────────────

class _DataFreshPill extends StatefulWidget {
  const _DataFreshPill();

  @override
  State<_DataFreshPill> createState() => _DataFreshPillState();
}

class _DataFreshPillState extends State<_DataFreshPill> {
  String? _label;

  @override
  void initState() {
    super.initState();
    _loadSyncTime();
  }

  Future<void> _loadSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt('home_last_sync_ms') ?? 0;
    if (lastMs == 0 || !mounted) return;
    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastMs));
    final label = switch (diff.inMinutes) {
      0 => 'Data fresh: updated just now',
      1 => 'Data fresh: updated 1m ago',
      final m when m < 60 => 'Data fresh: updated ${m}m ago',
      final m when m < 120 => 'Data fresh: updated 1h ago',
      final m => 'Data fresh: updated ${(m / 60).floor()}h ago',
    };
    if (mounted) setState(() => _label = label);
  }

  @override
  Widget build(BuildContext context) {
    final text = _label;
    if (text == null) return const SizedBox.shrink();
    final brightness = Theme.of(context).brightness;
    final border = AppColors.borderFor(brightness).withValues(alpha: 0.8);
    final background =
        AppColors.surfaceMutedFor(brightness).withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
