import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:flutter/material.dart';

class QuarantineQueueScreen extends StatelessWidget {
  const QuarantineQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder: Will be connected to Riverpod provider in Phase 3
    return SecondaryPageShell(
      title: 'Review Queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low-confidence SMS imports',
                  style: AppTypography.sectionTitle(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and confirm transactions before they\'re added to your account',
                  style: AppTypography.bodySm(context)
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.listGap),
              itemBuilder: (_, index) => _QuarantineItemCard(
                title: ['M-Pesa Transfer', 'Paybill Payment', 'Buy Goods'][index],
                amount: [1500.0, 2000.0, 750.0][index],
                date: DateTime.now().subtract(Duration(days: index + 1)),
                confidence: MpesaConfidence.medium,
                rawMessage: 'Sample M-Pesa message text...',
                onApprove: () {},
                onReject: () {},
                onEdit: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuarantineItemCard extends StatelessWidget {
  const _QuarantineItemCard({
    required this.title,
    required this.amount,
    required this.date,
    required this.confidence,
    required this.rawMessage,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
  });

  final String title;
  final double amount;
  final DateTime date;
  final MpesaConfidence confidence;
  final String rawMessage;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final confidenceColor = switch (confidence) {
      MpesaConfidence.high => AppColors.success,
      MpesaConfidence.medium => AppColors.warning,
      MpesaConfidence.low => AppColors.danger,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.bodySm(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.money(amount),
                    style: AppTypography.amount(context),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.smAll,
                      border: Border.all(
                        color: confidenceColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '${confidence.name} confidence',
                      style: AppTypography.bodySm(context).copyWith(
                        color: confidenceColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: AppRadius.mdAll,
            ),
            child: Text(
              rawMessage,
              style: AppTypography.bodySm(context)
                  .copyWith(color: AppColors.textSecondary, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
