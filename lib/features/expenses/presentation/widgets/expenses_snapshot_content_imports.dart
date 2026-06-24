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
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      tone: GlassCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import Confidence Routing', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppCapsule(
                label: 'Review: ${metrics.reviewQueueCount}',
                color: AppColors.warning,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
              AppCapsule(
                label: 'Quarantine: ${metrics.quarantineCount}',
                color: AppColors.danger,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
              AppCapsule(
                label: 'Retry Queue: ${metrics.retryQueueCount}',
                color: AppColors.accent,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
              AppCapsule(
                label: 'Failed: ${metrics.failedQueueCount}',
                color: AppColors.danger,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
            ],
          ),
          if (metrics.retryQueueCount > 0 || metrics.failedQueueCount > 0) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onReplayImportQueue,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Replay Import Queue'),
              ),
            ),
          ],
          if (reviewItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Needs review', style: textTheme.bodyLarge),
            const SizedBox(height: 8),
            ...reviewItems.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                                style: textTheme.bodyMedium,
                              ),
                              Text(
                                '${item.category} · ${CurrencyFormatter.money(item.amountKes)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Approve',
                          onPressed: busy ? null : () => onApproveReview(item),
                          icon: const Icon(Icons.check_circle_outline),
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          onPressed: busy ? null : () => onRejectReview(item),
                          icon: const Icon(Icons.cancel_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (quarantineItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Quarantine', style: textTheme.bodyLarge),
            const SizedBox(height: 8),
            ...quarantineItems.take(2).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                                style: textTheme.bodyMedium,
                              ),
                              Text(
                                'Confidence ${(item.confidence * 100).toStringAsFixed(0)}%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss',
                          onPressed:
                              busy ? null : () => onDismissQuarantine(item),
                          icon: const Icon(Icons.done_outline),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (paybillProfiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Paybill Registry', style: textTheme.bodyLarge),
            const SizedBox(height: 8),
            ...paybillProfiles.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                                style: textTheme.bodyMedium,
                              ),
                              Text(
                                '${item.paybill} · ${item.usageCount} uses',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _txDateFormat.format(item.lastSeenAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
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
