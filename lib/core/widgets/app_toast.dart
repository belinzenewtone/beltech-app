import 'dart:async';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Model ────────────────────────────────────────────────────────────────────

enum ToastType { success, error, info, warning }

class ToastMessage {
  const ToastMessage({
    required this.id,
    required this.message,
    required this.type,
  });
  final int id;
  final String message;
  final ToastType type;
}

// ── Provider ─────────────────────────────────────────────────────────────────

class ToastNotifier extends Notifier<List<ToastMessage>> {
  int _nextId = 0;

  @override
  List<ToastMessage> build() => [];

  void show(String message, {ToastType type = ToastType.info}) {
    final id = _nextId++;
    state = [...state, ToastMessage(id: id, message: message, type: type)];
    // Auto-dismiss after 3 200ms (matches RN DURATION constant).
    Future.delayed(const Duration(milliseconds: 3200), () {
      dismiss(id);
    });
  }

  void success(String message) => show(message, type: ToastType.success);
  void error(String message) => show(message, type: ToastType.error);
  void info(String message) => show(message, type: ToastType.info);
  void warning(String message) => show(message, type: ToastType.warning);

  void dismiss(int id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final toastProvider =
    NotifierProvider<ToastNotifier, List<ToastMessage>>(ToastNotifier.new);

// ── Overlay widget ────────────────────────────────────────────────────────────

/// Place this once at the top of AppShell's Stack to display toast messages.
class AppToastOverlay extends ConsumerWidget {
  const AppToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastProvider);
    if (toasts.isEmpty) return const SizedBox.shrink();

    // Position toasts at the top of the screen, outside the safe area
    // but below the status bar — identical to the RN ToastContainer position.
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 20,
      right: 20,
      child: Column(
        children: toasts
            .map((t) => _ToastItem(key: ValueKey(t.id), toast: t))
            .toList(),
      ),
    );
  }
}

class _ToastItem extends ConsumerStatefulWidget {
  const _ToastItem({super.key, required this.toast});
  final ToastMessage toast;

  @override
  ConsumerState<_ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends ConsumerState<_ToastItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // Slide down from above (matching RN toast animation direction).
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _accentColor => switch (widget.toast.type) {
    ToastType.success => AppColors.success,
    ToastType.error => AppColors.danger,
    ToastType.warning => AppColors.warning,
    ToastType.info => AppColors.accent,
  };

  IconData get _icon => switch (widget.toast.type) {
    ToastType.success => Icons.check_circle_rounded,
    ToastType.error => Icons.error_rounded,
    ToastType.warning => Icons.warning_rounded,
    ToastType.info => Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = _accentColor;

    // RN-style elevated pill: surface background with coloured icon and
    // a subtle tinted border. No coloured left-bar — the icon carries the
    // semantic colour instead.
    final bg = brightness == Brightness.light
        ? Colors.white
        : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(
                  color: accent.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(_icon, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.toast.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryFor(brightness),
                        height: 1.35,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref
                        .read(toastProvider.notifier)
                        .dismiss(widget.toast.id),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AppColors.textMutedFor(brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
