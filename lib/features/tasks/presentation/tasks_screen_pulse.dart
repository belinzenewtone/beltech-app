part of 'tasks_screen.dart';

class _TaskPulseBar extends StatelessWidget {
  const _TaskPulseBar({required this.tasks});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final done = tasks.where((t) => t.completed).length;
    final open = total - done;
    final doneRatio = done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PulseCount(value: open, label: 'Open', color: AppColors.accent),
            const Spacer(),
            _PulseCount(
              value: done,
              label: 'Done',
              color: AppColors.success,
              alignRight: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            height: 5,
            child: LinearProgressIndicator(
              value: doneRatio,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseCount extends StatelessWidget {
  const _PulseCount({
    required this.value,
    required this.label,
    required this.color,
    this.alignRight = false,
  });

  final int value;
  final String label;
  final Color color;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final children = [
      Text(
        '$value',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: AppTypography.metaText(context)),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alignRight ? children.reversed.toList() : children,
    );
  }
}
