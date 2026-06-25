import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Convenience helpers used by the app router ────────────────────────────────
//
// The router runs outside of a widget tree and cannot inject a provider,
// so it calls the repository directly via a one-shot ProviderContainer.
// Keeping these as package-level functions preserves the existing router
// call-site while the actual persistence is delegated to the repository.

/// Returns `true` if the user has already completed onboarding.
///
/// Uses a temporary [ProviderContainer] so the router can call this without
/// a widget context.
Future<bool> hasSeenOnboarding() async {
  final container = ProviderContainer();
  try {
    final repo = container.read(onboardingRepositoryProvider);
    return await repo.hasSeenOnboarding();
  } finally {
    container.dispose();
  }
}

/// Marks onboarding as complete. See [hasSeenOnboarding] for rationale.
Future<void> markOnboardingDone() async {
  final container = ProviderContainer();
  try {
    final repo = container.read(onboardingRepositoryProvider);
    await repo.markOnboardingDone();
  } finally {
    container.dispose();
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.auto_awesome_rounded,
    title: 'Welcome to BELTECH',
    body:
        'Track money, tasks, schedule, and focus in one connected daily system.',
  ),
  _OnboardingPage(
    icon: Icons.account_balance_wallet_rounded,
    title: 'Finance made simple',
    body:
        'Capture spending quickly and keep your budget posture always visible.',
  ),
  _OnboardingPage(
    icon: Icons.task_alt_rounded,
    title: 'Plan and execute',
    body:
        'Own your priorities with tasks, recurring automation, and calendar context.',
  ),
  _OnboardingPage(
    icon: Icons.bolt_rounded,
    title: 'Weekly intelligence',
    body: 'Review assistant guidance powered by your real workspace data.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingRepositoryProvider).markOnboardingDone();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  right: AppSpacing.md,
                ),
                child: GestureDetector(
                  onTap: _finish,
                  child: Text(
                    'Skip',
                    style: AppTypography.bodySm(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(flex: 2),
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              page.icon,
                              size: 44,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page.title,
                          style: AppTypography.pageTitle(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(page.body, style: AppTypography.bodyMd(context)),
                        const Spacer(flex: 3),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: SafeArea(
                top: false,
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            width: i == _page ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i == _page
                                  ? AppColors.accent
                                  : AppColors.borderSubtle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: _page == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        onPressed: _next,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
