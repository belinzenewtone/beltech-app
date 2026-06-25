import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
import 'package:flutter/material.dart';

class LoanItemCard extends StatelessWidget {
  const LoanItemCard({required this.loan, this.onTap, super.key});
  final LoanItem loan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final statusColor = _statusColor(loan.status);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.name,
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (loan.lender != null && loan.lender!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    loan.lender!,
                    style: AppTypography.bodySm(
                      context,
                    ).copyWith(color: AppColors.textSecondaryFor(brightness)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: loan.progressPercent,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceMutedFor(brightness),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${loan.outstandingAmount.toStringAsFixed(0)}',
                style: AppTypography.bodyMd(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  loan.status.label,
                  style: AppTypography.label(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 18,
          ),
        ],
      ),
    );
  }

  Color _statusColor(LoanStatus status) => switch (status) {
    LoanStatus.active => AppColors.warning,
    LoanStatus.cleared => AppColors.success,
    LoanStatus.defaulted => AppColors.danger,
  };
}
