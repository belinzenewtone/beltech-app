import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/stagger_reveal.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:beltech/features/home/presentation/widgets/spending_chart.dart';
import 'package:flutter/material.dart';

class HomeOverviewContent extends StatelessWidget {
  const HomeOverviewContent({required this.overview, super.key});

  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StaggerReveal(
                delay: const Duration(milliseconds: 30),
                child: HomeSummaryCard(
                  title: 'Today',
                  amount: CurrencyFormatter.money(overview.todayKes),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StaggerReveal(
                delay: const Duration(milliseconds: 80),
                child: HomeSummaryCard(
                  title: 'This Week',
                  amount: CurrencyFormatter.money(overview.weekKes),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        StaggerReveal(
          delay: const Duration(milliseconds: 130),
          child: HomeInfoCard(
            icon: Icons.check_circle_outlined,
            title: 'Productivity',
            subtitle:
                '${overview.completedCount} done · ${overview.pendingCount} pending',
          ),
        ),
        const SizedBox(height: AppSpacing.listGap),
        StaggerReveal(
          delay: const Duration(milliseconds: 180),
          child: HomeInfoCard(
            icon: Icons.calendar_month_outlined,
            title: 'Upcoming Events',
            subtitle: overview.upcomingEventsCount == 0
                ? 'No upcoming events'
                : '${overview.upcomingEventsCount} upcoming',
          ),
        ),
        const SizedBox(height: AppSpacing.listGap),
        StaggerReveal(
          delay: const Duration(milliseconds: 230),
          child: WeeklySpendingCard(dayValues: overview.weeklySpendingKes),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Recent Transactions', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: AppSpacing.sm),
        for (final tx in overview.recentTransactions) ...[
          HomeTransactionCard(
            title: tx.title,
            category: tx.category,
            amount: CurrencyFormatter.money(tx.amountKes),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class HomeSummaryCard extends StatelessWidget {
  const HomeSummaryCard({required this.title, required this.amount, super.key});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.label(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(amount, style: AppTypography.amount(context)),
        ],
      ),
    );
  }
}

class HomeInfoCard extends StatelessWidget {
  const HomeInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
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
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle(context)),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(subtitle, style: AppTypography.bodySm(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklySpendingCard extends StatelessWidget {
  const WeeklySpendingCard({required this.dayValues, super.key});

  final Map<String, double> dayValues;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Spending', style: AppTypography.sectionTitle(context)),
          const SizedBox(height: AppSpacing.md),
          SpendingChart(dayValues: dayValues),
        ],
      ),
    );
  }
}

class HomeTransactionCard extends StatelessWidget {
  const HomeTransactionCard({
    required this.title,
    required this.category,
    required this.amount,
    super.key,
  });

  final String title;
  final String category;
  final String amount;

  @override
  Widget build(BuildContext context) {
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
              Icons.payments_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle(context)),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(category, style: AppTypography.bodySm(context)),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.bodyMd(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
