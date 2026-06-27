part of 'home_spending_cards.dart';

const _kAiInsightSeenKey = 'ai_insight_seen';

/// Teaser card prompting the user to open the AI assistant.
/// Shows a "NEW" badge only the first time it is seen, then hides it.
class HomeAiInsightCard extends StatefulWidget {
  const HomeAiInsightCard({super.key});

  @override
  State<HomeAiInsightCard> createState() => _HomeAiInsightCardState();
}

class _HomeAiInsightCardState extends State<HomeAiInsightCard> {
  bool _showNew = false;

  @override
  void initState() {
    super.initState();
    _loadBadgeState();
  }

  Future<void> _loadBadgeState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_kAiInsightSeenKey) ?? false;
    if (mounted) {
      setState(() => _showNew = !seen);
    }
  }

  Future<void> _markSeen() async {
    if (!_showNew) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAiInsightSeenKey, true);
    if (mounted) setState(() => _showNew = false);
  }

  @override
  Widget build(BuildContext context) {
    final br = Theme.of(context).brightness;
    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: _markSeen,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedFor(br),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'AI Insight',
                        style: AppTypography.cardTitle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_showNew) ...[
                      const SizedBox(width: 6),
                      const AppCapsule(
                        label: 'NEW',
                        color: AppColors.accent,
                        variant: AppCapsuleVariant.subtle,
                        size: AppCapsuleSize.sm,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Ask for spending tips or weekly summaries.',
                  style: AppTypography.bodySm(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ── Weekly Money Brief ────────────────────────────────────────────────────────

/// Rule-based insight card that gives a one-glance weekly money summary.
class HomeWeeklyMoneyBrief extends StatelessWidget {
  const HomeWeeklyMoneyBrief({super.key, required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final topCategory = _topCategory(overview.recentTransactions);

    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMutedFor(brightness),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text('Weekly Brief', style: AppTypography.cardTitle(context)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _BriefStat(
                  label: 'This Week',
                  value: CurrencyFormatter.compact(overview.weekKes),
                ),
              ),
              const SizedBox(width: 8),
              if (topCategory != null)
                Expanded(
                  child: _BriefStat(label: 'Top Category', value: topCategory),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _topCategory(List<HomeTransaction> txns) {
    if (txns.isEmpty) return null;
    final totals = <String, double>{};
    for (final tx in txns) {
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amountKes;
    }
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class _BriefStat extends StatelessWidget {
  const _BriefStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedFor(brightness),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.bodyMd(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.bodySm(context)),
        ],
      ),
    );
  }
}

/// Task completion progress bar card.
class HomeProductivityCard extends StatelessWidget {
  const HomeProductivityCard({super.key, required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    final total = overview.completedCount + overview.pendingCount;
    final progress = total == 0 ? 0.0 : overview.completedCount / total;
    final brightness = Theme.of(context).brightness;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedFor(brightness),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.borderFor(
                      brightness,
                    ).withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${overview.completedCount} done · ${overview.pendingCount} pending',
                  style: AppTypography.bodySm(context),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
