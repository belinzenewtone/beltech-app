import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/insights/domain/entities/insight_card.dart';
import 'package:beltech/features/insights/presentation/providers/insights_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insightsProvider);

    return SecondaryPageShell(
      title: 'Insights',
      child: state.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const AppEmptyState(
              icon: Icons.insights_outlined,
              title: 'No insights yet',
              subtitle:
                  'Add transactions, tasks, and budgets to generate insights.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                child: Text(
                  'AI-powered financial intelligence',
                  style: AppTypography.bodySm(context),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: cards.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.listGap),
                  itemBuilder: (_, i) => _InsightCardWidget(card: cards[i]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (_, __) => const AppEmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load insights',
          subtitle: 'Pull to retry',
        ),
      ),
    );
  }
}

class _InsightCardWidget extends StatelessWidget {
  const _InsightCardWidget({required this.card});
  final InsightCard card;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tone: _glassTone,
      accentColor: _accentColor,
      onTap: card.actionRoute != null
          ? () => context.pushNamed(card.actionRoute!)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(_icon, size: 18, color: _accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  card.title,
                  style: AppTypography.cardTitle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(card.body, style: AppTypography.bodySm(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ConfidenceBadge(confidence: card.confidence),
              const Spacer(),
              Text(
                _relativeTime(card.generatedAt),
                style: AppTypography.metaText(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  GlassCardTone get _glassTone {
    return switch (card.tone) {
      InsightTone.positive || InsightTone.warning => GlassCardTone.accent,
      InsightTone.neutral || InsightTone.info => GlassCardTone.muted,
    };
  }

  Color get _accentColor {
    return switch (card.tone) {
      InsightTone.positive => AppColors.success,
      InsightTone.warning => AppColors.warning,
      InsightTone.info => AppColors.info,
      InsightTone.neutral => AppColors.textSecondary,
    };
  }

  IconData get _icon {
    return switch (card.kind) {
      InsightKind.spending => Icons.trending_up_rounded,
      InsightKind.savings => Icons.savings_rounded,
      InsightKind.taskCompletion => Icons.task_alt_rounded,
      InsightKind.anomaly => Icons.warning_amber_rounded,
      InsightKind.health => Icons.monitor_heart_outlined,
      InsightKind.cashFlow => Icons.account_balance_wallet_rounded,
      InsightKind.budget => Icons.pie_chart_rounded,
      InsightKind.general => Icons.lightbulb_outline_rounded,
    };
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = confidence >= 0.7
        ? AppColors.success
        : confidence >= 0.4
            ? AppColors.warning
            : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '${pct}% confidence',
        style: AppTypography.metaText(context).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
