import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/insights/domain/entities/insight_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Renders a list of InsightCard items for the Insights tab.
/// Mirrors Kotlin InsightRow cards in InsightsScreen Insights tab.
class InsightsSection extends StatelessWidget {
  const InsightsSection({super.key, required this.insights});

  final List<InsightCard> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Insights',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ...insights.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InsightRow(card: card),
            )),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.card});

  final InsightCard card;

  Color _accentColor() {
    return switch (card.tone) {
      InsightTone.positive => AppColors.success,
      InsightTone.warning => AppColors.warning,
      InsightTone.info => AppColors.accent,
      InsightTone.neutral => const Color(0xFF6B7280),
    };
  }

  IconData _icon() {
    return switch (card.kind) {
      InsightKind.spending => Icons.trending_up_rounded,
      InsightKind.savings => Icons.savings_rounded,
      InsightKind.taskCompletion => Icons.task_alt_rounded,
      InsightKind.anomaly => Icons.warning_amber_rounded,
      InsightKind.health => Icons.favorite_rounded,
      InsightKind.cashFlow => Icons.account_balance_wallet_rounded,
      InsightKind.budget => Icons.pie_chart_rounded,
      InsightKind.general => Icons.lightbulb_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor();
    return AppCard(
      accentColor: color,
      onTap: card.actionRoute != null
          ? () => context.pushNamed(card.actionRoute!)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(), size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  card.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          if (card.actionRoute != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
        ],
      ),
    );
  }
}
