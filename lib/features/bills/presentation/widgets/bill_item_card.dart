import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:flutter/material.dart';

class BillItemCard extends StatelessWidget {
  const BillItemCard({
    super.key,
    required this.bill,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
  });

  final BillItem bill;
  final VoidCallback onTogglePaid;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isOverdue = bill.dueDate.isBefore(DateTime.now()) && !bill.paid;

    return AppCard(
      tone: bill.paid ? AppCardTone.muted : AppCardTone.standard,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd(context).copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: bill.paid ? TextDecoration.lineThrough : null,
                    color: bill.paid
                        ? AppColors.textMuted
                        : AppColors.textPrimaryFor(brightness),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(bill.dueDate)}${isOverdue ? ' · Overdue' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(context).copyWith(
                    color: isOverdue
                        ? AppColors.danger
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.formatKes(bill.amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd(context).copyWith(
              fontWeight: FontWeight.w700,
              color: bill.paid
                  ? AppColors.textMuted
                  : AppColors.textPrimaryFor(brightness),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  bill.paid ? 'Mark unpaid' : 'Mark paid',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (value) {
              switch (value) {
                case 'toggle':
                  onTogglePaid();
                case 'edit':
                  onEdit();
                case 'delete':
                  onDelete();
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}
