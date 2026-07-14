import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:flutter/material.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryPageShell(
      title: "What's New",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _entries.map((e) => _EntryCard(entry: e)).toList(),
      ),
    );
  }
}

class _ChangelogEntry {
  const _ChangelogEntry({
    required this.version,
    required this.date,
    required this.items,
    this.isLatest = false,
  });

  final String version;
  final String date;
  final List<String> items;
  final bool isLatest;
}

const _entries = [
  _ChangelogEntry(
    version: '1.3.0',
    date: 'Jun 2026',
    isLatest: true,
    items: [
      'Categorize screen — fast-batch recategorisation with quick-pick chips',
      'Finance Dashboard shows Today · Week (with trend delta) · Month',
      'Week-over-week spend delta with colour-coded direction badge',
    ],
  ),
  _ChangelogEntry(
    version: '1.2.0',
    date: 'May 2026',
    items: [
      '4-tier SMS deduplication (M-Pesa code → source hash → semantic hash → heuristic)',
      'Fuliza overdraft tracking: negative-balance loans auto-detected from SMS',
      'SMS import quarantine queue for low-confidence messages',
      'Intent classification: 17 AI-understood transaction categories',
    ],
  ),
  _ChangelogEntry(
    version: '1.1.0',
    date: 'Apr 2026',
    items: [
      'Merchant detail drill-down with per-merchant spend timeline',
      'Fee analytics screen: M-Pesa charges breakdown by period',
      'SMS confidence scoring badge on transaction rows',
      'CSV import with column-mapping wizard',
    ],
  ),
  _ChangelogEntry(
    version: '1.0.0',
    date: 'Mar 2026',
    items: [
      'Launch: M-Pesa SMS auto-import with 6-stage parsing pipeline',
      'Budget, Income, Recurring Bills, Goals, Loans management',
      'AI Financial Assistant (offline, on-device)',
      'Week Review ritual, Insights, and Analytics dashboard',
    ],
  ),
];

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});
  final _ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
      child: AppCard(
        tone: AppCardTone.muted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.version,
                  style: AppTypography.cardTitle(
                    context,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                if (entry.isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Latest',
                      style: AppTypography.bodySm(context).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  entry.date,
                  style: AppTypography.bodySm(
                    context,
                  ).copyWith(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...entry.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: AppColors.accent,
                      ),
                    ),
                    Expanded(
                      child: Text(item, style: AppTypography.bodySm(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
