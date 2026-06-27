import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/core/widgets/stagger_reveal.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:beltech/features/home/presentation/providers/home_providers.dart';
import 'package:beltech/features/home/presentation/widgets/home_spending_cards.dart';
import 'package:beltech/features/home/presentation/widgets/home_hub_card.dart';
import 'package:beltech/features/home/presentation/widgets/home_tools_row.dart';
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
    final displayName = ref.watch(
      profileProvider.select((s) {
        final p = s.valueOrNull;
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DAILY FOCUS', style: AppTypography.eyebrow(context)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      greeting,
                      style: AppTypography.pageTitle(context),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('settings');
                    },
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                  ),
                ],
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
          delay: Duration(milliseconds: 110),
          child: HomeToolsRow(),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        SizedBox(height: AppSpacing.fabBottom(context)),
      ],
    );
  }
}
