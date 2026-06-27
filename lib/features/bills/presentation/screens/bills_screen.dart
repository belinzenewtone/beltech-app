import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_icon_pill_button.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:beltech/features/bills/presentation/providers/bills_providers.dart';
import 'package:beltech/features/bills/presentation/widgets/bill_form_sheet.dart';
import 'package:beltech/features/bills/presentation/widgets/bill_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsState = ref.watch(billsProvider);
    final commitmentState = ref.watch(monthlyCommitmentProvider);

    ref.listen<AsyncValue<void>>(billsWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(context, 'Unable to save bill changes.');
      }
    });

    return SecondaryPageShell(
      title: 'Bills',
      scrollable: false,
      actions: [
        AppIconPillButton(
          icon: Icons.add_rounded,
          label: 'Add',
          tone: AppIconPillTone.accent,
          onPressed: () => _showAddBill(context, ref),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommitmentCard(commitmentState: commitmentState),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: billsState.when(
              data: (bills) {
                if (bills.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(
                        width: double.infinity,
                        child: AppEmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'No bills yet',
                          subtitle:
                              'Add your first bill to start tracking payments.',
                        ),
                      ),
                    ],
                  );
                }
                final unpaid = bills.where((b) => !b.paid).toList();
                final paid = bills.where((b) => b.paid).toList();
                return ListView(
                  padding: EdgeInsets.only(
                    left: AppSpacing.screenHorizontal,
                    right: AppSpacing.screenHorizontal,
                    bottom: AppSpacing.fabBottom(context),
                  ),
                  children: [
                    if (unpaid.isNotEmpty) ...[
                      _SectionHeader(title: 'Upcoming · ${unpaid.length}'),
                      const SizedBox(height: AppSpacing.sm),
                      ...unpaid.map(
                        (bill) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: BillItemCard(
                            bill: bill,
                            onTogglePaid: () => _togglePaid(context, ref, bill),
                            onEdit: () => _showEditBill(context, ref, bill),
                            onDelete: () => _confirmDelete(context, ref, bill),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (paid.isNotEmpty) ...[
                      _SectionHeader(title: 'Paid · ${paid.length}'),
                      const SizedBox(height: AppSpacing.sm),
                      ...paid.map(
                        (bill) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: BillItemCard(
                            bill: bill,
                            onTogglePaid: () => _togglePaid(context, ref, bill),
                            onEdit: () => _showEditBill(context, ref, bill),
                            onDelete: () => _confirmDelete(context, ref, bill),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => ErrorMessage(label: '$e'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBill(BuildContext context, WidgetRef ref) async {
    final result = await showBillFormSheet(context);
    if (result == null) return;
    await ref
        .read(billsWriteControllerProvider.notifier)
        .addBill(
          name: result.name,
          amount: result.amount,
          dueDate: result.dueDate,
          urgency: result.urgency,
          recurrence: result.recurrence,
        );
  }

  Future<void> _showEditBill(
    BuildContext context,
    WidgetRef ref,
    BillItem bill,
  ) async {
    final result = await showBillFormSheet(context, existing: bill);
    if (result == null) return;
    await ref
        .read(billsWriteControllerProvider.notifier)
        .updateBill(
          id: bill.id,
          name: result.name,
          amount: result.amount,
          dueDate: result.dueDate,
          urgency: result.urgency,
          recurrence: result.recurrence,
          paid: result.paid,
        );
  }

  Future<void> _togglePaid(
    BuildContext context,
    WidgetRef ref,
    BillItem bill,
  ) async {
    await ref
        .read(billsWriteControllerProvider.notifier)
        .updateBill(id: bill.id, paid: !bill.paid);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BillItem bill,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text(
          'Delete "${bill.name}"?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(billsWriteControllerProvider.notifier).deleteBill(bill.id);
    }
  }
}

class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({required this.commitmentState});

  final AsyncValue<double> commitmentState;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Monthly commitment',
              style: AppTypography.bodyMd(context),
            ),
          ),
          commitmentState.when(
            data: (total) => Text(
              CurrencyFormatter.formatKes(total),
              style: AppTypography.bodyMd(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            loading: () => const SizedBox(
              width: 60,
              height: 14,
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => const Text('—'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.eyebrow(
        context,
      ).copyWith(color: AppColors.textMuted, letterSpacing: 0.4),
    );
  }
}
