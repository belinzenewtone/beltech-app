import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/recurring/domain/services/recurring_suggestion_service.dart';
import 'package:flutter/material.dart';

class RecurringSuggestions extends StatelessWidget {
  const RecurringSuggestions({
    super.key,
    required this.suggestions,
    required this.onAdd,
  });

  final List<SuggestedRecurringTemplate> suggestions;
  final ValueChanged<SuggestedRecurringTemplate> onAdd;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected patterns',
            style: AppTypography.sectionTitle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'These merchants or amounts repeat. Create a recurring template?',
            style: AppTypography.bodySm(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          ...suggestions.map((s) => _SuggestionRow(suggestion: s, onAdd: onAdd)),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.onAdd});

  final SuggestedRecurringTemplate suggestion;
  final ValueChanged<SuggestedRecurringTemplate> onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${suggestion.category} · ${suggestion.cadence.name} · '
                  '${suggestion.sampleCount} times',
                  style: AppTypography.bodySm(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            CurrencyFormatter.formatKes(suggestion.amountKes),
            style: AppTypography.bodySm(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: 'Add',
            size: AppButtonSize.sm,
            onPressed: () => onAdd(suggestion),
          ),
        ],
      ),
    );
  }
}
