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
    return GlassCard(
      tone: GlassCardTone.muted,
      padding: const EdgeInsets.all(14),
      onTap: _markSeen,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.violet,
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
                        color: AppColors.violet,
                        variant: AppCapsuleVariant.subtle,
                        size: AppCapsuleSize.sm,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Ask your assistant for spending tips, task priorities, or weekly summaries.',
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
    final topCategory = _topCategory(overview.recentTransactions);
    final tip = _tip(overview);

    return GlassCard(
      tone: GlassCardTone.muted,
      accentColor: AppColors.teal,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.teal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Weekly Brief',
                style: AppTypography.cardTitle(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BriefStat(
                  label: 'This Week',
                  value: CurrencyFormatter.compact(overview.weekKes),
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              if (topCategory != null)
                Expanded(
                  child: _BriefStat(
                    label: 'Top Category',
                    value: topCategory,
                    color: AppColors.teal,
                  ),
                ),
            ],
          ),
          if (tip != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 13, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  String? _tip(HomeOverview ov) {
    if (ov.weekKes == 0) return 'Track your first spend — tap Finance.';
    if (ov.pendingCount > 5) {
      return '${ov.pendingCount} tasks open — keep momentum today.';
    }
    if (ov.todayKes > ov.weekKes * 0.4) {
      return "Today's spend is over 40% of this week — watch the pace.";
    }
    if (ov.weekKes > 0 && ov.completedCount > 2) {
      return 'Great progress — ${ov.completedCount} tasks done and spending tracked.';
    }
    return null;
  }
}

class _BriefStat extends StatelessWidget {
  const _BriefStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
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

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor:
                        AppColors.borderFor(brightness).withValues(alpha: 0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.teal),
                  ),
                ),
                const SizedBox(height: 4),
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
