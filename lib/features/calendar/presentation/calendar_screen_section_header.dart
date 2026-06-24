part of 'calendar_screen.dart';

class _CalendarSectionHeader extends StatelessWidget {
  const _CalendarSectionHeader({
    required this.title,
    required this.dateLabel,
    required this.pendingCount,
    required this.completedCount,
    required this.showCompleted,
    required this.onToggleCompleted,
  });

  final String title;
  final String dateLabel;
  final int pendingCount;
  final int completedCount;
  final bool showCompleted;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: textTheme.titleMedium)),
            AppIconPillButton(
              icon: showCompleted
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: showCompleted ? 'Hide done' : 'Show done',
              tone: AppIconPillTone.subtle,
              onPressed: onToggleCompleted,
            ),
            const SizedBox(width: 8),
            Text(
              dateLabel,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pending $pendingCount · Done $completedCount',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
