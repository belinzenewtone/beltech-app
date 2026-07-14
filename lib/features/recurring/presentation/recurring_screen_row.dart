part of 'recurring_screen.dart';

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.template,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  final RecurringTemplate template;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    final date = template.nextRunAt;
    final isPaused = !template.enabled;

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey('recurring-${template.id}'),
        direction: busy ? DismissDirection.none : DismissDirection.horizontal,
        movementDuration: AppMotion.swipe(context),
        resizeDuration: AppMotion.resize(context),
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.4,
          DismissDirection.endToStart: 0.4,
        },
        confirmDismiss: (direction) async {
          AppHaptics.lightImpact();
          if (direction == DismissDirection.startToEnd) {
            onEdit();
            return false;
          }
          if (direction == DismissDirection.endToStart) {
            onDelete();
            return false;
          }
          return false;
        },
        background: const _RecurringSwipeBackground(
          color: AppColors.warningMuted,
          icon: Icons.edit_outlined,
          label: 'Edit',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: const _RecurringSwipeBackground(
          color: AppColors.dangerMuted,
          icon: Icons.delete_outline,
          label: 'Delete',
          alignment: Alignment.centerRight,
        ),
        child: Opacity(
          opacity: isPaused ? 0.6 : 1.0,
          child: AppCard(
            tone: AppCardTone.muted,
            onTap: busy ? null : onEdit,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: AppTypography.bodyMd(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${template.cadence.name} · ${DateFormat('MMM d').format(date)}',
                        style: AppTypography.bodySm(context),
                      ),
                    ],
                  ),
                ),
                if (template.amountKes != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.money(template.amountKes!),
                    style: AppTypography.bodyMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: template.kind == RecurringKind.income
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    ); // RepaintBoundary + Dismissible
  }
}

class _RecurringSwipeBackground extends StatelessWidget {
  const _RecurringSwipeBackground({
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
          const SizedBox(height: AppSpacing.xs),
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
