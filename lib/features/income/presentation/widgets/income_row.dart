import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/income/domain/entities/income_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _IncomeRowAction { edit, delete }

class IncomeRow extends StatelessWidget {
  const IncomeRow({
    super.key,
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final IncomeItem item;
  final bool busy;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final swipeDuration = AppMotion.swipe(context);
    final resizeDuration = AppMotion.resize(context);
    final sourceColor = _sourceColor(item.source);

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey('income-${item.id}'),
        direction: busy ? DismissDirection.none : DismissDirection.horizontal,
        movementDuration: swipeDuration,
        resizeDuration: resizeDuration,
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.4,
          DismissDirection.endToStart: 0.4,
        },
        confirmDismiss: (direction) async {
          AppHaptics.lightImpact();
          if (direction == DismissDirection.startToEnd) {
            await onEdit();
            return false;
          }
          if (direction == DismissDirection.endToStart) {
            await onDelete();
            return false;
          }
          return false;
        },
        background: const _IncomeSwipeBg(
          color: AppColors.warningMuted,
          icon: Icons.edit_outlined,
          label: 'Edit',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: const _IncomeSwipeBg(
          color: AppColors.dangerMuted,
          icon: Icons.delete_outline,
          label: 'Delete',
          alignment: Alignment.centerRight,
        ),
        child: GlassCard(
          tone: GlassCardTone.muted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          onTap: busy
              ? null
              : () {
                  onEdit();
                },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: sourceColor.withValues(alpha: 0.16),
                child: Icon(
                  _sourceIcon(item.source),
                  size: 18,
                  color: sourceColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.cardTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppCapsule(
                          label: item.source.isEmpty ? 'Income' : item.source,
                          color: sourceColor,
                          variant: AppCapsuleVariant.subtle,
                          size: AppCapsuleSize.sm,
                        ),
                        AppCapsule(
                          label:
                              DateFormat('MMM d, yyyy').format(item.receivedAt),
                          color: AppColors.textMuted,
                          variant: AppCapsuleVariant.subtle,
                          size: AppCapsuleSize.sm,
                          icon: Icons.schedule_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      CurrencyFormatter.money(item.amountKes),
                      style: AppTypography.bodyMd(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PopupMenuButton<_IncomeRowAction>(
                    enabled: !busy,
                    tooltip: 'Income actions',
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textMuted,
                    ),
                    onSelected: (action) {
                      if (action == _IncomeRowAction.edit) {
                        onEdit();
                        return;
                      }
                      onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _IncomeRowAction.edit,
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: _IncomeRowAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _kSources = [
    (
      ['salary', 'payroll', 'wages', 'wage'],
      AppColors.success,
      Icons.work_outline_rounded,
    ),
    (
      ['freelance', 'contract', 'gig', 'client'],
      AppColors.accent,
      Icons.computer_outlined,
    ),
    (
      ['business', 'sales', 'revenue', 'profit'],
      AppColors.teal,
      Icons.store_outlined,
    ),
    (
      ['investment', 'dividend', 'interest', 'capital', 'stock', 'shares'],
      AppColors.categoryGrowth,
      Icons.trending_up_rounded,
    ),
    (
      ['rental', 'rent', 'lease', 'property'],
      AppColors.categoryBill,
      Icons.home_outlined,
    ),
    (
      ['gift', 'bonus', 'award', 'prize'],
      AppColors.warning,
      Icons.card_giftcard_outlined,
    ),
  ];

  Color _sourceColor(String source) => _matchSource(source).$1;
  IconData _sourceIcon(String source) => _matchSource(source).$2;

  (Color, IconData) _matchSource(String source) {
    final tokens = source
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();
    for (final (keywords, color, icon) in _kSources) {
      if (keywords.any(tokens.contains)) return (color, icon);
    }
    return (AppColors.textSecondary, Icons.account_balance_wallet_outlined);
  }
}

class _IncomeSwipeBg extends StatelessWidget {
  const _IncomeSwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
