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
    final typeColor = AppColors.categoryColorFor(template.category ?? 'other');
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
          child: GlassCard(
            tone: GlassCardTone.muted,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            onTap: busy ? null : onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: AppTypography.cardTitle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              AppCapsule(
                                label: template.kind.name,
                                color: typeColor,
                                variant: AppCapsuleVariant.subtle,
                                size: AppCapsuleSize.sm,
                              ),
                              AppCapsule(
                                label: template.cadence.name,
                                color: AppColors.slate,
                                variant: AppCapsuleVariant.subtle,
                                size: AppCapsuleSize.sm,
                                icon: Icons.repeat_rounded,
                              ),
                              AppCapsule(
                                label: DateFormat('MMM d').format(date),
                                color: AppColors.textMuted,
                                variant: AppCapsuleVariant.subtle,
                                size: AppCapsuleSize.sm,
                                icon: Icons.schedule_rounded,
                              ),
                              if (isPaused)
                                const AppCapsule(
                                  label: 'Paused',
                                  color: AppColors.textMuted,
                                  variant: AppCapsuleVariant.outline,
                                  size: AppCapsuleSize.sm,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (template.amountKes != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          CurrencyFormatter.money(template.amountKes!),
                          style: AppTypography.bodyMd(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: template.kind == RecurringKind.income
                                ? AppColors.success
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isPaused
                            ? 'Paused · was ${DateFormat('MMM d').format(date)}'
                            : 'Next: ${DateFormat('MMM d, yyyy').format(date)}',
                        style: AppTypography.bodySm(context),
                      ),
                    ),
                    GestureDetector(
                      onTap: busy ? null : onToggleEnabled,
                      child: AppCapsule(
                        label: isPaused ? 'Resume' : 'Pause',
                        color:
                            isPaused ? AppColors.accent : AppColors.textMuted,
                        variant: AppCapsuleVariant.subtle,
                        size: AppCapsuleSize.sm,
                        icon: isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                    ),
                  ],
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
