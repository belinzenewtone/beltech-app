import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/core/widgets/stagger_reveal.dart';
import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:beltech/features/home/presentation/providers/home_providers.dart';
import 'package:beltech/features/home/presentation/widgets/home_spending_cards.dart';
import 'package:beltech/features/home/presentation/widgets/home_hub_card.dart';
import 'package:beltech/features/home/presentation/widgets/home_tools_row.dart';
import 'package:beltech/features/home/presentation/widgets/home_week_review_ritual_card.dart';
import 'package:beltech/features/auth/presentation/providers/account_providers.dart';
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
  // Cached once per mount — date label does not change within a session.
  late final String _todayLabel;

  @override
  void initState() {
    super.initState();
    _todayLabel = _buildTodayLabel(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(homeOverviewProvider);
    // select() — only rebuild HomeScreen when the first name or email changes,
    // not on every unrelated profile field update (avatar, bio, phone, etc.).
    final (firstName, email) = ref.watch(
      profileProvider.select((s) {
        final p = s.valueOrNull;
        // Extract first word and cap at 10 chars so the greeting fits on
        // all screen sizes. Accounts created before the limit was added keep
        // their full name in storage; we just display fewer characters here.
        final raw = p?.name.trim().split(' ').first ?? '';
        final capped = raw.length > 10 ? raw.substring(0, 10) : raw;
        return (capped, p?.email ?? '');
      }),
    );
    final greeting = _greeting(firstName);
    final initials = firstName.isNotEmpty
        ? firstName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'B');

    return PageShell(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryFor(
                          Theme.of(context).brightness,
                        ),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _todayLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('analytics');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      AppHaptics.lightImpact();
                      _showProfileSheet(
                        context,
                        ref,
                        firstName,
                        email,
                        initials,
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? AppColors.surfaceFor(Theme.of(context).brightness)
                            : AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Greeting ─────────────────────────────────────────────────────────
          Text(
            greeting,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimaryFor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 24),

          // ── Content ──────────────────────────────────────────────────────────
          overviewState.when(
            loading: () => const HomeSkeletonList(),
            error: (_, __) => AppEmptyState(
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
    final hour = DateTime.now().hour;
    final salutation = switch (hour) {
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

  void _showProfileSheet(
    BuildContext context,
    WidgetRef ref,
    String firstName,
    String email,
    String initials,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileQuickSheet(
        firstName: firstName,
        email: email,
        initials: initials,
        onGoToProfile: () {
          Navigator.of(context).pop();
          ref.read(shellTabIndexProvider.notifier).state =
              ShellTab.profile.index;
        },
        onSignOut: () async {
          Navigator.of(context).pop();
          await ref.read(accountAuthControllerProvider.notifier).signOut();
        },
      ),
    );
  }
}

// ── Dashboard overview section ────────────────────────────────────────────────

class _HomeOverviewSection extends StatelessWidget {
  const _HomeOverviewSection({required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggerReveal(
          delay: const Duration(milliseconds: 30),
          child: HomeSpendSnapshotStrip(overview: overview),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        StaggerReveal(
          delay: const Duration(milliseconds: 55),
          child: HomeHubCard(overview: overview),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const StaggerReveal(
          delay: Duration(milliseconds: 80),
          child: HomeWeekReviewRitualCard(),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const StaggerReveal(
          delay: Duration(milliseconds: 110),
          child: HomeToolsRow(),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        SizedBox(height: AppSpacing.fabBottom(context)),
      ],
    );
  }
}

// ── Profile quick sheet ───────────────────────────────────────────────────────

class _ProfileQuickSheet extends StatelessWidget {
  const _ProfileQuickSheet({
    required this.firstName,
    required this.email,
    required this.initials,
    required this.onGoToProfile,
    required this.onSignOut,
  });

  final String firstName;
  final String email;
  final String initials;
  final VoidCallback onGoToProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardBottom = mediaQuery.viewInsets.bottom;
    final safeBottom = mediaQuery.padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: keyboardBottom + safeBottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // avatar + name + email
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.accent.withValues(alpha: 0.18),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (firstName.isNotEmpty)
            Text(
              firstName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              email,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 28),
          // Go to Profile
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGoToProfile,
              icon: const Icon(Icons.person_outline_rounded, size: 18),
              label: const Text('Go to Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Sign Out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.danger),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
