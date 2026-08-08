import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/core/widgets/stagger_reveal.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expense_dialogs.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:beltech/features/home/presentation/providers/home_providers.dart';
import 'package:beltech/features/home/presentation/widgets/home_spending_cards.dart';
import 'package:beltech/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Cached once per mount — date label and greeting hour don't change mid-session.
  late final String _todayLabel;
  late final int _greetingHour;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayLabel = _buildTodayLabel(now);
    _greetingHour = now.hour;
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(homeOverviewProvider);
    // select() — only rebuild HomeScreen when the first name or email changes,
    // not on every unrelated profile field update (avatar, bio, phone, etc.).
    final displayName = ref.watch(
      profileProvider.select((s) {
        final p = s.value;
        // Prefer username (capped at 8 chars). Fall back to first name.
        final rawUsername = p?.username.trim() ?? '';
        if (rawUsername.isNotEmpty) {
          return rawUsername.length > 8
              ? rawUsername.substring(0, 8)
              : rawUsername;
        }
        final raw = p?.name.trim().split(' ').first ?? '';
        return raw.length > 8 ? raw.substring(0, 8) : raw;
      }),
    );
    final greeting = _greeting(displayName);

    return PageShell(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          PageHeader(
            eyebrow: 'Daily Focus',
            title: greeting,
            subtitle: _todayLabel,
            action: IconButton(
              onPressed: () {
                AppHaptics.lightImpact();
                context.pushNamed('settings');
              },
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Content ──────────────────────────────────────────────────────────
          overviewState.when(
            loading: () => const HomeSkeletonList(),
            error: (_, _) => AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load dashboard',
              subtitle: 'Please try again',
              iconColor: AppColors.danger,
              action: AppButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(homeOverviewProvider),
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
              ),
            ),
            data: (overview) => _HomeOverviewSection(overview: overview),
          ),
        ],
      ),
    );
  }

  String _greeting(String firstName) {
    final salutation = switch (_greetingHour) {
      >= 5 && < 12 => 'Good Morning',
      >= 12 && < 17 => 'Good Afternoon',
      >= 17 && < 21 => 'Good Evening',
      _ => 'Good Night',
    };
    return firstName.isEmpty ? salutation : '$salutation, $firstName';
  }

  // Format: "Tuesday, Mar 24" — matches the RN reference exactly (abbreviated
  // month, no ordinal suffix, clean and compact).
  String _buildTodayLabel(DateTime now) {
    final weekday = DateFormat('EEEE').format(now);
    final monthDay = DateFormat('MMM d').format(now);
    return '$weekday, $monthDay';
  }
}

// ── Dashboard overview section ────────────────────────────────────────────────

class _HomeOverviewSection extends ConsumerWidget {
  const _HomeOverviewSection({required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recent transactions for instant feedback after adding
    final snapshot = ref.watch(expensesSnapshotProvider).value;
    final recentTxns = snapshot?.transactions.take(5).toList() ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggerReveal(
          delay: const Duration(milliseconds: 30),
          child: HomeSpendSnapshotStrip(overview: overview),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        // Quick-add row — add expense or income in one tap
        StaggerReveal(
          delay: const Duration(milliseconds: 55),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  icon: Icons.add_rounded,
                  label: 'Add Expense',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  onPressed: () async {
                    final input = await showAddExpenseDialog(context);
                    if (input == null || !context.mounted) return;
                    await ref
                        .read(expenseWriteControllerProvider.notifier)
                        .addExpense(
                          title: input.title,
                          category: input.category,
                          amountKes: input.amountKes,
                          occurredAt: input.occurredAt,
                        );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  icon: Icons.attach_money_rounded,
                  label: 'Add Income',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  onPressed: () => context.pushNamed('income'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        // Recent transactions — immediate confirmation
        if (recentTxns.isNotEmpty) ...[
          StaggerReveal(
            delay: const Duration(milliseconds: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent', style: AppTypography.sectionTitle(context)),
                TextButton(
                  onPressed: () => ref
                      .read(shellTabIndexProvider.notifier)
                      .state = 1, // switch to Finance
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          StaggerReveal(
            delay: const Duration(milliseconds: 95),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < recentTxns.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              recentTxns[i].title.isNotEmpty
                                  ? recentTxns[i].title
                                  : 'Transaction',
                              style: AppTypography.bodyMd(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.money(recentTxns[i].amountKes),
                            style: AppTypography.bodyMd(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.fabBottom(context)),
        ],
      ],
    );
  }
}
