import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/stagger_reveal.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:beltech/features/home/presentation/widgets/spending_chart.dart';
import 'package:flutter/material.dart';

class HomeOverviewContent extends StatelessWidget {
  const HomeOverviewContent({required this.overview, super.key});

  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                  tone: GlassCardTone.accent,
                  accentColor: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StaggerReveal(
                delay: const Duration(milliseconds: 80),
                child: HomeSummaryCard(
                  title: 'This Week',
                  amount: CurrencyFormatter.money(overview.weekKes),
                  tone: GlassCardTone.accent,
                  accentColor: AppColors.violet,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StaggerReveal(
          delay: const Duration(milliseconds: 130),
          child: HomeInfoCard(
            icon: Icons.check_circle,
            title: 'Productivity',
            subtitle:
                '${overview.completedCount} completed today · ${overview.pendingCount} pending',
            color: AppColors.teal,
          ),
        ),
        const SizedBox(height: 14),
        StaggerReveal(
          delay: const Duration(milliseconds: 180),
          child: HomeInfoCard(
            icon: Icons.event,
            title: 'Upcoming Events',
            subtitle: overview.upcomingEventsCount == 0
                ? 'No upcoming events'
                : '${overview.upcomingEventsCount} upcoming events',
            color: AppColors.violet,
          ),
        ),
        const SizedBox(height: 14),
        StaggerReveal(
          delay: const Duration(milliseconds: 230),
          child: WeeklySpendingCard(dayValues: overview.weeklySpendingKes),
        ),
        const SizedBox(height: 14),
        Text('Recent Transactions', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final tx in overview.recentTransactions) ...[
          HomeTransactionCard(
            title: tx.title,
            category: tx.category,
            amount: CurrencyFormatter.money(tx.amountKes),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class HomeSummaryCard extends StatelessWidget {
  const HomeSummaryCard({
    required this.title,
    required this.amount,
    this.tone = GlassCardTone.standard,
    this.accentColor,
    super.key,
  });

  final String title;
  final String amount;
  final GlassCardTone tone;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      tone: tone,
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(amount, style: textTheme.titleMedium),
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
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.22),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: textTheme.bodyMedium),
            ],
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
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Spending', style: textTheme.titleMedium),
          const SizedBox(height: 12),
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
    final textTheme = Theme.of(context).textTheme;
    final iconBackground = Theme.of(context).brightness == Brightness.light
        ? AppColors.accent.withValues(alpha: 0.16)
        : AppColors.accentSoft;
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconBackground,
            child: const Icon(Icons.payments_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyLarge),
                Text(category, style: textTheme.bodyMedium),
              ],
            ),
          ),
          Text(amount, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
