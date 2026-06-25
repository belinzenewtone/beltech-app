part of 'expenses_snapshot_content.dart';

class _ImportPipelineCard extends StatelessWidget {
  const _ImportPipelineCard({
    required this.metrics,
    required this.reviewItems,
    required this.quarantineItems,
    required this.paybillProfiles,
    required this.fulizaEvents,
    required this.busy,
    required this.onApproveReview,
    required this.onRejectReview,
    required this.onDismissQuarantine,
    required this.onReplayImportQueue,
  });

  final ExpenseImportMetrics metrics;
  final List<ExpenseReviewItem> reviewItems;
  final List<ExpenseQuarantineItem> quarantineItems;
  final List<PaybillProfile> paybillProfiles;
  final List<FulizaLifecycleEvent> fulizaEvents;
  final bool busy;
  final ValueChanged<ExpenseReviewItem> onApproveReview;
  final ValueChanged<ExpenseReviewItem> onRejectReview;
  final ValueChanged<ExpenseQuarantineItem> onDismissQuarantine;
  final Future<void> Function() onReplayImportQueue;

  @override
  Widget build(BuildContext context) {
    if (metrics.reviewQueueCount == 0 &&
        metrics.quarantineCount == 0 &&
        metrics.retryQueueCount == 0 &&
        metrics.failedQueueCount == 0 &&
        paybillProfiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import pipeline', style: AppTypography.cardTitle(context)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppCapsule(
                label: 'Review ${metrics.reviewQueueCount}',
                color: AppColors.warning,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
              AppCapsule(
                label: 'Quarantine ${metrics.quarantineCount}',
                color: AppColors.danger,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
              AppCapsule(
                label:
                    'Pending ${metrics.retryQueueCount + metrics.failedQueueCount}',
                color: AppColors.accent,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
            ],
          ),
          if (metrics.retryQueueCount > 0 || metrics.failedQueueCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onReplayImportQueue,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Replay'),
              ),
            ),
          ],
          if (reviewItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Needs review', style: AppTypography.bodyMd(context)),
            const SizedBox(height: AppSpacing.sm),
            ...reviewItems
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMd(context),
                              ),
                              Text(
                                '${item.category} · ${CurrencyFormatter.money(item.amountKes)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm(context),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Approve',
                          onPressed: busy ? null : () => onApproveReview(item),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          onPressed: busy ? null : () => onRejectReview(item),
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (quarantineItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Quarantine', style: AppTypography.bodyMd(context)),
            const SizedBox(height: AppSpacing.sm),
            ...quarantineItems
                .take(2)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.reason,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMd(context),
                              ),
                              Text(
                                '${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm(context),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss',
                          onPressed: busy
                              ? null
                              : () => onDismissQuarantine(item),
                          icon: const Icon(Icons.done_outline, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (paybillProfiles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Paybill registry', style: AppTypography.bodyMd(context)),
            const SizedBox(height: AppSpacing.sm),
            ...paybillProfiles
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMd(context),
                              ),
                              Text(
                                '${item.paybill} · ${item.usageCount} uses',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
