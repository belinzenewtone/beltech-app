part of 'week_review_screen.dart';

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final ({String label, String value, Color color}) topLeft;
  final ({String label, String value, Color color}) topRight;
  final ({String label, String value, Color color}) bottomLeft;
  final ({String label, String value, Color color}) bottomRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: topLeft.label,
                value: topLeft.value,
                color: topLeft.color,
              ),
            ),
            const SizedBox(width: AppSpacing.listGap),
            Expanded(
              child: _StatCard(
                label: topRight.label,
                value: topRight.value,
                color: topRight.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.listGap),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: bottomLeft.label,
                value: bottomLeft.value,
                color: bottomLeft.color,
              ),
            ),
            const SizedBox(width: AppSpacing.listGap),
            Expanded(
              child: _StatCard(
                label: bottomRight.label,
                value: bottomRight.value,
                color: bottomRight.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.amount(context).copyWith(color: color),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
              Icon(_iconFor(label), size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySm(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String label) {
    return switch (label) {
      'Tasks Done' => Icons.check_circle_outline,
      'Open Tasks' => Icons.pending_actions,
      'Weekly Spend' => Icons.trending_down,
      'Income' => Icons.trending_up,
      _ => Icons.info_outline,
    };
  }
}

class _LoadingReview extends StatelessWidget {
  const _LoadingReview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          tone: AppCardTone.muted,
          child: Container(
            height: 80,
            alignment: Alignment.center,
            child: const LoadingIndicator(),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          tone: AppCardTone.muted,
          child: Container(
            height: 120,
            alignment: Alignment.center,
            child: const LoadingIndicator(),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          tone: AppCardTone.muted,
          child: Container(
            height: 60,
            alignment: Alignment.center,
            child: const LoadingIndicator(),
          ),
        ),
      ],
    );
  }
}
