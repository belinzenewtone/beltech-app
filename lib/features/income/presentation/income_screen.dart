import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_icon_pill_button.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:beltech/features/income/presentation/providers/income_providers.dart';
import 'package:beltech/features/income/presentation/widgets/income_dialogs.dart';
import 'package:beltech/features/income/presentation/widgets/income_overview_cards.dart';
import 'package:beltech/features/income/presentation/widgets/income_row.dart';
import 'package:beltech/features/income/presentation/widgets/income_trend_chart.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/providers/global_search_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesState = ref.watch(incomesProvider);
    final overviewState = ref.watch(incomeOverviewProvider);
    final writeState = ref.watch(incomeWriteControllerProvider);

    ref.listen<AsyncValue<void>>(incomeWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            AppFeedback.error(context, 'Unable to save income changes.');
          }
        });
      } else if (previous is AsyncLoading && next is AsyncData<void>) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            AppFeedback.success(context, 'Income changes saved successfully.');
          }
        });
      }
    });

    return SecondaryPageShell(
      title: 'Income',

      scrollable: false,
      actions: [
        AppIconPillButton(
          icon: Icons.add_rounded,
          label: 'Add',
          tone: AppIconPillTone.accent,
          onPressed: writeState.isLoading
              ? null
              : () async {
                  final input = await showIncomeDialog(context);
                  if (input == null) {
                    return;
                  }
                  await ref
                      .read(incomeWriteControllerProvider.notifier)
                      .addIncome(
                        title: input.title,
                        amountKes: input.amountKes,
                        receivedAt: input.receivedAt,
                      );
                },
        ),
      ],
      child: incomesState.when(
        data: (incomes) {
          _consumeSearchTarget(context, ref, incomes);
          if (incomes.isEmpty) {
            return const AppEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No income records',
              subtitle: 'Add your first income source',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              overviewState.when(
                data: (overview) => IncomeOverviewCards(overview: overview),
                loading: () => const Center(child: LoadingIndicator()),
                error: (_, _) => const AppCard(
                  child: Text('Unable to load cashflow insights right now.'),
                ),
              ),
              const SizedBox(height: 12),
              overviewState.when(
                data: (overview) => IncomeTrendChart(trend: overview.trend),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: incomes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = incomes[index];
                    return IncomeRow(
                      item: item,
                      busy: writeState.isLoading,
                      onEdit: () async {
                        final input = await showIncomeDialog(
                          context,
                          initialTitle: item.title,
                          initialAmount: item.amountKes,
                          initialDate: item.receivedAt,
                        );
                        if (input == null) {
                          return;
                        }
                        await ref
                            .read(incomeWriteControllerProvider.notifier)
                            .updateIncome(
                              incomeId: item.id,
                              title: input.title,
                              amountKes: input.amountKes,
                              receivedAt: input.receivedAt,
                            );
                      },
                      onDelete: () async {
                        final confirmed = await showDeleteConfirmDialog(
                          context,
                          title: 'Delete income',
                          body:
                              'Remove "${item.title}" (${CurrencyFormatter.money(item.amountKes)})? This cannot be undone.',
                        );
                        if (confirmed != true || !context.mounted) return;
                        await ref
                            .read(incomeWriteControllerProvider.notifier)
                            .deleteIncome(item.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (_, _) => ErrorMessage(
          label: 'Unable to load incomes',
          onRetry: () => ref.invalidate(incomesProvider),
        ),
      ),
    );
  }

  void _consumeSearchTarget(
    BuildContext context,
    WidgetRef ref,
    List<IncomeItem> incomes,
  ) {
    final pendingTarget = ref.read(globalSearchDeepLinkTargetProvider);
    if (pendingTarget?.kind != GlobalSearchKind.income) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() async {
        if (!context.mounted) {
          return;
        }
        final target = ref.read(globalSearchDeepLinkTargetProvider);
        if (target?.kind != GlobalSearchKind.income) {
          return;
        }
        ref.read(globalSearchDeepLinkTargetProvider.notifier).state = null;

        final recordId = target?.recordId;
        if (recordId == null) {
          return;
        }
        final item = incomes
            .where((income) => income.id == recordId)
            .firstOrNull;
        if (item == null) {
          AppFeedback.info(context, 'This income record no longer exists.');
          return;
        }

        final input = await showIncomeDialog(
          context,
          initialTitle: item.title,
          initialAmount: item.amountKes,
          initialDate: item.receivedAt,
        );
        if (input == null) {
          return;
        }
        await ref
            .read(incomeWriteControllerProvider.notifier)
            .updateIncome(
              incomeId: item.id,
              title: input.title,
              amountKes: input.amountKes,
              receivedAt: input.receivedAt,
            );
      });
    });
  }
}
