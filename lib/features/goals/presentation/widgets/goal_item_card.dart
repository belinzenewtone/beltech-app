import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/goals/domain/entities/goal_item.dart';
import 'package:flutter/material.dart';

class GoalItemCard extends StatelessWidget {
  const GoalItemCard({required this.goal, this.onTap, super.key});
  final GoalItem goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final percent = (goal.progressPercent * 100).clamp(0, 100).toStringAsFixed(0);
    final atRisk = goal.isAtRisk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(goal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd(context)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (atRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text('At Risk',
                          style: AppTypography.bodySm(context).copyWith(
                            color: AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('XAF ${goal.currentAmount.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd(context)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(' / XAF ${goal.targetAmount.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(context).copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      )),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: goal.progressPercent.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceMutedFor(brightness),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      atRisk ? AppColors.danger : AppColors.success),
                ),
              ),
              const SizedBox(height: 6),
              Text('$percent%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(context).copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
