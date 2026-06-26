import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FulizaSettingsCard extends ConsumerWidget {
  const FulizaSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(fulizaOutstandingBalanceProvider);
    final limitAsync = ref.watch(fulizaLimitProvider);
    final brightness = Theme.of(context).brightness;

    final balance = balanceAsync.valueOrNull ?? 0;
    final limit = limitAsync.valueOrNull ?? 0;
    final hasActivity = balance > 0;

    return AppCard(
      tone: AppCardTone.muted,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: hasActivity ? AppColors.warning : AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fuliza M-Pesa',
                    style: AppTypography.cardTitle(context),
                  ),
                ),
                if (hasActivity)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      'Active',
                      style: AppTypography.bodySm(context).copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'Outstanding',
                    value: balanceAsync.when(
                      data: (v) => v > 0 ? CurrencyFormatter.formatKes(v) : '—',
                      loading: () => '…',
                      error: (_, __) => '—',
                    ),
                    valueColor: hasActivity ? AppColors.danger : AppColors.textSecondaryFor(brightness),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCell(
                    label: 'Your limit',
                    value: limitAsync.when(
                      data: (v) => v > 0 ? CurrencyFormatter.formatKes(v) : 'Not set',
                      loading: () => '…',
                      error: (_, __) => '—',
                    ),
                    valueColor: AppColors.textPrimaryFor(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, indent: 16, endIndent: 16),
          InkWell(
            onTap: () => _showEditLimit(context, ref, limit),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppRadius.xl),
              bottomRight: Radius.circular(AppRadius.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Fuliza limit',
                    style: AppTypography.bodySm(context).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditLimit(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fuliza Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your Fuliza M-Pesa limit to track how much of it you've used.",
              style: AppTypography.bodySm(ctx),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Limit (KES)',
                prefixText: 'KES ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              final value = double.tryParse(text) ?? 0;
              Navigator.of(ctx).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !context.mounted) return;
    await ref
        .read(notificationPreferenceControllerProvider.notifier)
        .setFulizaLimit(result);
    if (context.mounted) {
      AppFeedback.success(context, 'Fuliza limit updated', ref: ref);
    }
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySm(context)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.cardTitle(context).copyWith(color: valueColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
