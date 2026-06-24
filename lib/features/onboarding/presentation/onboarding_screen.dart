import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
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

/// Marks onboarding as complete.  See [hasSeenOnboarding] for rationale.
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
    required this.color,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.auto_awesome_rounded,
    title: 'Welcome to\nBELTECH',
    body:
        'Track money, tasks, schedule, and focus in one connected daily system built for how you actually live.',
    color: Color(0xFF2F80FF),
  ),
  _OnboardingPage(
    icon: Icons.account_balance_wallet_rounded,
    title: 'Finance That\nFeels Native',
    body:
        'Capture spending quickly, import M-Pesa SMS data, and keep your budget posture always visible.',
    color: Color(0xFF26C4B6),
  ),
  _OnboardingPage(
    icon: Icons.task_alt_rounded,
    title: 'Execution\n& Planning',
    body:
        'Own your priorities with tasks, recurring automation, and calendar context in one unified view.',
    color: Color(0xFF8B6DFF),
  ),
  _OnboardingPage(
    icon: Icons.bolt_rounded,
    title: 'Weekly\nIntelligence',
    body:
        'Get assistant guidance and review insights powered by your real workspace data - not generic tips.',
    color: Color(0xFFF4A838),
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
    return Container(
      color: AppColors.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: page.color.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: page.color.withValues(alpha: 0.33),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: page.color.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    page.icon,
                                    size: 40,
                                    color: page.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    page.title,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    page.body,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: List.generate(
                            _pages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.only(right: 8),
                              width: i == _page ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i == _page
                                    ? _pages[_page].color
                                    : _pages[_page].color.withValues(alpha: 0.26),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_page == _pages.length - 1)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _pages[_page].color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _finish,
                            child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          )
                        else
                          Row(
                            children: [
                              if (_page > 0) ...[
                                GestureDetector(
                                  onTap: () => _controller.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  ),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _pages[_page].color.withValues(alpha: 0.26),
                                        width: 1.5,
                                      ),
                                    ),
                                     child: const Icon(
                                       Icons.arrow_back_rounded,
                                       size: 20,
                                       color: AppColors.textSecondary,
                                     ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ] else
                                const SizedBox(width: 48 + 12),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _pages[_page].color,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _next,
                                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24, top: 16),
                  child: GestureDetector(
                    onTap: _finish,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: AppTypography.sm,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
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
