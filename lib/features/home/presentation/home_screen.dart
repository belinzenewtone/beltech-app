import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
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
                    Text('DAILY FOCUS', style: AppTypography.eyebrow(context)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      greeting,
                      style: AppTypography.pageTitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _todayLabel,
                      style: AppTypography.bodyMd(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  AppHaptics.lightImpact();
                  _showProfileSheet(context, ref, firstName, email, initials);
                },
                child: Container(
                  width: AppSpacing.xl,
                  height: AppSpacing.xl,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppColors.surfaceFor(Theme.of(context).brightness)
                        : AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.55),
                      width: AppSpacing.xs / 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTypography.label(context).copyWith(
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
          const SizedBox(height: AppSpacing.lg),

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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.sm + AppSpacing.xs,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: keyboardBottom + safeBottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: AppSpacing.lg + AppSpacing.md,
            height: AppSpacing.xs / 2,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSpacing.xs / 4),
            ),
          ),
          // avatar + name + email
          CircleAvatar(
            radius: AppSpacing.lg,
            backgroundColor: AppColors.accent.withValues(alpha: 0.18),
            child: Text(
              initials,
              style: AppTypography.headlineMd(
                context,
              ).copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (firstName.isNotEmpty)
            Text(firstName, style: AppTypography.headlineSm(context)),
          if (email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              email,
              style: AppTypography.bodySm(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
          // Go to Profile
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Go to Profile',
              icon: Icons.person_outline_rounded,
              fullWidth: true,
              onPressed: onGoToProfile,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.danger,
              fullWidth: true,
              onPressed: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}
