import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:beltech/core/logger/app_logger.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_fields.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/calendar_add_screen_models.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:beltech/features/calendar/presentation/widgets/event_dialog_helpers.dart';

/// Full-screen add/edit form for calendar entries.
///
/// Uses the BELTECH design identity: rounded surface cards, accent-tinted
/// icons, full-width priority buttons, pill tab selector, and text save action.
class CalendarAddScreen extends ConsumerStatefulWidget {
  const CalendarAddScreen({super.key, this.args});

  final CalendarAddInitialArgs? args;

  @override
  ConsumerState<CalendarAddScreen> createState() => _CalendarAddScreenState();
}

class _CalendarAddScreenState extends ConsumerState<CalendarAddScreen>
    with SingleTickerProviderStateMixin {
  static const List<CalendarAddTab> _tabs = CalendarAddTab.values;

  late TabController _tabController;

  // Common
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _guestsController = TextEditingController();

  CalendarEventType _type = CalendarEventType.personal;
  CalendarEventPriority _priority = CalendarEventPriority.neutral;
  bool _allDay = false;
  DateTime _startAt = DateTime.now();
  DateTime? _endAt;
  RepeatRule _repeatRule = RepeatRule.never;
  List<int> _reminderOffsets = const [];
  int _reminderTimeOfDayMinutes = 9 * 60; // 09:00
  String _timeZoneId = _deviceTimeZoneId();

  CalendarEvent? _existingEvent;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialTab = widget.args?.defaultTab ?? CalendarAddTab.task;
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _tabs.indexOf(initialTab),
    );
    _tabController.addListener(_onTabChanged);

    final event = widget.args?.editingEvent;
    final selectedDate = widget.args?.selectedDate;
    if (event != null) {
      _existingEvent = event;
      _titleController.text = event.title;
      _noteController.text = event.note ?? '';
      _guestsController.text = event.guests;
      _type = event.type;
      _priority = event.priority;
      _allDay = event.allDay;
      _startAt = event.startAt;
      _endAt = event.endAt;
      _repeatRule = event.repeatRule;
      _reminderOffsets = List.unmodifiable(event.reminderOffsets);
      _reminderTimeOfDayMinutes = event.reminderTimeOfDayMinutes;
      _timeZoneId = event.timeZoneId.isEmpty ? _deviceTimeZoneId() : event.timeZoneId;

      // Sync tab to the persisted kind.
      final kindIndex = _tabs.indexWhere((t) => t.toKind() == event.kind);
      if (kindIndex >= 0 && kindIndex != _tabController.index) {
        _tabController.index = kindIndex;
      }
    } else {
      final base = selectedDate ?? DateTime.now();
      _startAt = _roundToNextFiveMinutes(
        DateTime(base.year, base.month, base.day, 9, 0),
      );
      _endAt = _startAt.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _guestsController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tab = _tabs[_tabController.index];

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _existingEvent != null ? 'Edit ${tab.label}' : 'New ${tab.label}',
          style: AppTypography.sectionTitle(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Save',
              style: AppTypography.bodyMd(context).copyWith(
                color: _isSaving
                    ? AppColors.textMuted
                    : AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          _TabPillSelector(
            tabs: _tabs,
            selectedIndex: _tabController.index,
            onTap: (index) => _tabController.index = index,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map(_buildTabContent).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(CalendarAddTab tab) {
    switch (tab) {
      case CalendarAddTab.task:
        return _TaskFormContent(
          titleController: _titleController,
          noteController: _noteController,
          type: _type,
          priority: _priority,
          startAt: _startAt,
          reminderOffsets: _reminderOffsets,
          onTypeChanged: (v) => setState(() => _type = v),
          onPriorityChanged: (v) => setState(() => _priority = v),
          onStartAtChanged: (v) => setState(() => _startAt = v),
          onRemindersTap: _openRemindersPicker,
        );
      case CalendarAddTab.event:
        return _EventFormContent(
          titleController: _titleController,
          noteController: _noteController,
          guestsController: _guestsController,
          type: _type,
          priority: _priority,
          allDay: _allDay,
          startAt: _startAt,
          endAt: _endAt,
          repeatRule: _repeatRule,
          reminderOffsets: _reminderOffsets,
          timeZoneId: _timeZoneId,
          onTypeChanged: (v) => setState(() => _type = v),
          onPriorityChanged: (v) => setState(() => _priority = v),
          onAllDayChanged: (v) => setState(() => _allDay = v),
          onStartAtChanged: (v) => setState(() => _startAt = v),
          onEndAtChanged: (v) => setState(() => _endAt = v),
          onRepeatTap: _openRepeatPicker,
          onRemindersTap: _openRemindersPicker,
          onTimeZoneTap: _openTimeZonePicker,
        );
      case CalendarAddTab.birthday:
        return _BirthdayFormContent(
          titleController: _titleController,
          noteController: _noteController,
          startAt: _startAt,
          reminderOffsets: _reminderOffsets,
          onStartAtChanged: (v) => setState(() => _startAt = v),
          onRemindersTap: _openRemindersPicker,
        );
      case CalendarAddTab.anniversary:
        return _AnniversaryFormContent(
          titleController: _titleController,
          noteController: _noteController,
          startAt: _startAt,
          reminderOffsets: _reminderOffsets,
          onStartAtChanged: (v) => setState(() => _startAt = v),
          onRemindersTap: _openRemindersPicker,
        );
      case CalendarAddTab.countdown:
        return _CountdownFormContent(
          titleController: _titleController,
          noteController: _noteController,
          startAt: _startAt,
          onStartAtChanged: (v) => setState(() => _startAt = v),
        );
    }
  }

  static String _deviceTimeZoneId() {
    try {
      return DateTime.now().timeZoneName;
    } catch (_) {
      return 'UTC';
    }
  }

  static DateTime _roundToNextFiveMinutes(DateTime value) {
    final remainder = value.minute % 5;
    final add = remainder == 0 ? 5 : 5 - remainder;
    return DateTime(value.year, value.month, value.day, value.hour, value.minute + add);
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a title.');
      return;
    }

    final tab = _tabs[_tabController.index];
    final kind = tab.toKind();

    if (_endAt != null && _endAt!.isBefore(_startAt)) {
      _showError('End time must be after start time.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(calendarWriteControllerProvider.notifier);
      final offsets = List<int>.from(_reminderOffsets);

      if (_existingEvent != null) {
        await controller.updateEvent(
          eventId: _existingEvent!.id,
          title: title,
          startAt: _startAt,
          endAt: _endAt,
          priority: _priority,
          kind: kind,
          type: _type,
          note: _noteController.text.trim(),
          reminderOffsets: offsets,
          alarmEnabled: offsets.isNotEmpty,
          allDay: _allDay,
          repeatRule: _repeatRule,
          guests: _guestsController.text.trim(),
          timeZoneId: _timeZoneId,
          reminderTimeOfDayMinutes: _reminderTimeOfDayMinutes,
        );
      } else {
        await controller.addEvent(
          title: title,
          startAt: _startAt,
          endAt: _endAt,
          priority: _priority,
          kind: kind,
          type: _type,
          note: _noteController.text.trim(),
          reminderOffsets: offsets,
          alarmEnabled: offsets.isNotEmpty,
          allDay: _allDay,
          repeatRule: _repeatRule,
          guests: _guestsController.text.trim(),
          timeZoneId: _timeZoneId,
          reminderTimeOfDayMinutes: _reminderTimeOfDayMinutes,
        );
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (e, st) {
      AppLogger.error('Failed to save calendar event', error: e, stackTrace: st);
      _showError('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── Sub-page navigation ────────────────────────────────────────────────────

  Future<void> _openRemindersPicker() async {
    final result = await Navigator.of(context).push<RemindersPickerResult>(
      MaterialPageRoute(
        builder: (_) => _RemindersPickerPage(
          initialOffsets: _reminderOffsets,
          initialTimeOfDayMinutes: _reminderTimeOfDayMinutes,
          showAllDayStyle: _isAllDayStyle,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _reminderOffsets = List.unmodifiable(result.offsets);
        _reminderTimeOfDayMinutes = result.timeOfDayMinutes;
      });
    }
  }

  Future<void> _openRepeatPicker() async {
    final result = await Navigator.of(context).push<RepeatRule>(
      MaterialPageRoute(
        builder: (_) => _RepeatPickerPage(initialRule: _repeatRule),
      ),
    );
    if (result != null) {
      setState(() => _repeatRule = result);
    }
  }

  Future<void> _openTimeZonePicker() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _TimeZonePickerPage(initialZone: _timeZoneId),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _timeZoneId = result);
    }
  }

  bool get _isAllDayStyle {
    final tab = _tabs[_tabController.index];
    return _allDay || tab == CalendarAddTab.birthday || tab == CalendarAddTab.anniversary;
  }
}

// ── Top-level helpers ────────────────────────────────────────────────────────

Future<void> pickDateField({
  required BuildContext context,
  required DateTime initial,
  required ValueChanged<DateTime> onPicked,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate ?? DateTime(now.year - 10),
    lastDate: lastDate ?? DateTime(now.year + 50),
  );
  if (picked != null) {
    onPicked(DateTime(picked.year, picked.month, picked.day, initial.hour, initial.minute));
  }
}

Future<void> pickTimeField({
  required BuildContext context,
  required DateTime initial,
  required ValueChanged<DateTime> onPicked,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (picked != null) {
    onPicked(DateTime(initial.year, initial.month, initial.day, picked.hour, picked.minute));
  }
}

String formatDate(DateTime value) => DateFormat('EEE, MMM d, yyyy').format(value);
String formatMonthDay(DateTime value) => DateFormat('MMMM d').format(value);
String formatTime(DateTime value) => DateFormat.jm().format(value);

String formatReminderOffset(int offsetMinutes) {
  if (offsetMinutes == 0) return 'At time of event';
  if (offsetMinutes < 60) return '$offsetMinutes minutes before';
  if (offsetMinutes == 60) return '1 hour before';
  if (offsetMinutes < 1440) {
    final hours = offsetMinutes ~/ 60;
    return '$hours hours before';
  }
  if (offsetMinutes == 1440) return '1 day before';
  final days = offsetMinutes ~/ 1440;
  return '$days days before';
}

String formatReminderSummary(List<int> offsets) {
  if (offsets.isEmpty) return 'None';
  if (offsets.length == 1) return formatReminderOffset(offsets.first);
  return '${offsets.length} reminders';
}

// ── Tab selector ─────────────────────────────────────────────────────────────

class _TabPillSelector extends StatelessWidget {
  const _TabPillSelector({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<CalendarAddTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return AnimatedScale(
            scale: selected ? 1.0 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent
                        : brightness == Brightness.dark
                            ? AppColors.surfaceElevated
                            : AppColors.surfaceFor(brightness),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? AppColors.accent
                          : AppColors.borderFor(brightness).withValues(alpha: 0.55),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      tabs[index].label,
                      style: AppTypography.bodyMd(context).copyWith(
                        color: selected ? AppColors.textPrimary : AppColors.textSecondaryFor(brightness),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Shared form widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.bodyMd(context).copyWith(
          color: AppColors.textSecondaryFor(Theme.of(context).brightness),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.md,
      child: child,
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.bodySm(context)),
                    const SizedBox(height: 2),
                    Text(
                      value.isEmpty ? 'None' : value,
                      style: AppTypography.bodyMd(context).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondaryFor(brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label, style: AppTypography.bodyMd(context)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTypography.bodyMd(context).copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.accent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label, style: AppTypography.bodyMd(context)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.accent,
          inactiveTrackColor: AppColors.border,
        ),
      ],
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  final CalendarEventPriority selected;
  final ValueChanged<CalendarEventPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CalendarEventPriority.values.map((priority) {
        final option = eventPriorityOption(priority);
        final isSelected = selected == priority;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority == CalendarEventPriority.urgent ? 0 : 8,
            ),
            child: AppButton(
              label: option.label,
              size: AppButtonSize.sm,
              variant: isSelected ? AppButtonVariant.primary : AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => onChanged(priority),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  final CalendarEventType selected;
  final ValueChanged<CalendarEventType> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return _FormCard(
      child: DropdownButtonFormField<CalendarEventType>(
        initialValue: selected,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        dropdownColor: AppColors.surfaceFor(brightness),
        style: AppTypography.bodyMd(context).copyWith(
          color: AppColors.textPrimaryFor(brightness),
          fontWeight: FontWeight.w500,
        ),
        items: CalendarEventType.values.map((type) {
          final option = eventTypeOption(type);
          return DropdownMenuItem<CalendarEventType>(
            value: type,
            child: Row(
              children: [
                Icon(option.icon, size: 18, color: option.color),
                const SizedBox(width: 10),
                Text(option.label),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _GuestInput extends StatefulWidget {
  const _GuestInput({required this.controller});

  final TextEditingController controller;

  @override
  State<_GuestInput> createState() => _GuestInputState();
}

class _GuestInputState extends State<_GuestInput> {
  late final TextEditingController _inputController;
  final _focusNode = FocusNode();

  List<String> get _guests => widget.controller.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    final guests = _guests;
    for (final part in value.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty && !guests.contains(trimmed)) {
        guests.add(trimmed);
      }
    }
    widget.controller.text = guests.join(', ');
    _inputController.clear();
    setState(() {});
  }

  void _remove(String guest) {
    final guests = _guests..remove(guest);
    widget.controller.text = guests.join(', ');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final guests = _guests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _inputController,
          focusNode: _focusNode,
          textInputAction: TextInputAction.done,
          style: AppTypography.bodyMd(context),
          decoration: InputDecoration(
            hintText: 'Add guest (press enter or comma)',
            hintStyle: AppTypography.bodyMd(context).copyWith(
              color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.55),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () => _add(_inputController.text),
            ),
          ),
          onSubmitted: (value) {
            _add(value);
            _focusNode.requestFocus();
          },
          onChanged: (value) {
            if (value.contains(',')) {
              _add(value);
            }
          },
        ),
        if (guests.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: guests.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final guest = guests[index];
                return Chip(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelStyle: AppTypography.bodySm(context),
                  backgroundColor: AppColors.surfaceMutedFor(brightness),
                  side: BorderSide(color: AppColors.borderFor(brightness)),
                  label: Text(guest),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => _remove(guest),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Task form ────────────────────────────────────────────────────────────────

class _TaskFormContent extends StatelessWidget {
  const _TaskFormContent({
    required this.titleController,
    required this.noteController,
    required this.type,
    required this.priority,
    required this.startAt,
    required this.reminderOffsets,
    required this.onTypeChanged,
    required this.onPriorityChanged,
    required this.onStartAtChanged,
    required this.onRemindersTap,
  });

  final TextEditingController titleController;
  final TextEditingController noteController;
  final CalendarEventType type;
  final CalendarEventPriority priority;
  final DateTime startAt;
  final List<int> reminderOffsets;
  final ValueChanged<CalendarEventType> onTypeChanged;
  final ValueChanged<CalendarEventPriority> onPriorityChanged;
  final ValueChanged<DateTime> onStartAtChanged;
  final VoidCallback onRemindersTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTitleField(controller: titleController, hint: 'Task title'),
          const SizedBox(height: AppSpacing.md),
          AppNoteField(controller: noteController),
          const _SectionLabel('Priority'),
          _PrioritySelector(
            selected: priority,
            onChanged: onPriorityChanged,
          ),
          const _SectionLabel('Deadline'),
          _FormCard(
            child: _PickerRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: formatDate(startAt),
              onTap: () async {
                await pickDateField(
                  context: context,
                  initial: startAt,
                  onPicked: onStartAtChanged,
                );
              },
            ),
          ),
          _FormCard(
            child: _PickerRow(
              icon: Icons.access_time,
              label: 'Time',
              value: formatTime(startAt),
              onTap: () async {
                await pickTimeField(
                  context: context,
                  initial: startAt,
                  onPicked: onStartAtChanged,
                );
              },
            ),
          ),
          const _SectionLabel('Reminders'),
          _FormCard(
            child: _NavRow(
              icon: Icons.notifications_none,
              label: 'Reminders',
              value: formatReminderSummary(reminderOffsets),
              onTap: onRemindersTap,
            ),
          ),
          const _SectionLabel('Category'),
          _CategorySelector(
            selected: type,
            onChanged: onTypeChanged,
          ),
        ],
      ),
    );
  }
}

// ── Event form ───────────────────────────────────────────────────────────────

class _EventFormContent extends StatelessWidget {
  const _EventFormContent({
    required this.titleController,
    required this.noteController,
    required this.guestsController,
    required this.type,
    required this.priority,
    required this.allDay,
    required this.startAt,
    required this.endAt,
    required this.repeatRule,
    required this.reminderOffsets,
    required this.timeZoneId,
    required this.onTypeChanged,
    required this.onPriorityChanged,
    required this.onAllDayChanged,
    required this.onStartAtChanged,
    required this.onEndAtChanged,
    required this.onRepeatTap,
    required this.onRemindersTap,
    required this.onTimeZoneTap,
  });

  final TextEditingController titleController;
  final TextEditingController noteController;
  final TextEditingController guestsController;
  final CalendarEventType type;
  final CalendarEventPriority priority;
  final bool allDay;
  final DateTime startAt;
  final DateTime? endAt;
  final RepeatRule repeatRule;
  final List<int> reminderOffsets;
  final String timeZoneId;
  final ValueChanged<CalendarEventType> onTypeChanged;
  final ValueChanged<CalendarEventPriority> onPriorityChanged;
  final ValueChanged<bool> onAllDayChanged;
  final ValueChanged<DateTime> onStartAtChanged;
  final ValueChanged<DateTime?> onEndAtChanged;
  final VoidCallback onRepeatTap;
  final VoidCallback onRemindersTap;
  final VoidCallback onTimeZoneTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTitleField(controller: titleController, hint: 'Event title'),
          const SizedBox(height: AppSpacing.md),
          AppNoteField(controller: noteController),
          const _SectionLabel('All day'),
          _FormCard(
            child: _ToggleRow(
              icon: Icons.access_time,
              label: 'All day',
              value: allDay,
              onChanged: onAllDayChanged,
            ),
          ),
          const _SectionLabel('When'),
          _FormCard(
            child: Column(
              children: [
                _PickerRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'From',
                  value: allDay
                      ? formatDate(startAt)
                      : formatEventDateTimeLabel(context, startAt),
                  onTap: () => _pickStart(context),
                ),
                if (!allDay)
                  _PickerRow(
                    icon: Icons.access_time,
                    label: 'Start time',
                    value: formatTime(startAt),
                    onTap: () async {
                      await pickTimeField(
                        context: context,
                        initial: startAt,
                        onPicked: onStartAtChanged,
                      );
                    },
                  ),
                const Divider(height: 1),
                _PickerRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'To',
                  value: endAt == null
                      ? 'Set end date'
                      : allDay
                          ? formatDate(endAt!)
                          : formatEventDateTimeLabel(context, endAt!),
                  onTap: () => _pickEnd(context),
                ),
              ],
            ),
          ),
          const _SectionLabel('Repeat'),
          _FormCard(
            child: _NavRow(
              icon: Icons.repeat,
              label: 'Repeat',
              value: repeatRule.label,
              onTap: onRepeatTap,
            ),
          ),
          const _SectionLabel('Reminders'),
          _FormCard(
            child: _NavRow(
              icon: Icons.notifications_none,
              label: 'Reminders',
              value: formatReminderSummary(reminderOffsets),
              onTap: onRemindersTap,
            ),
          ),
          const _SectionLabel('Time zone'),
          _FormCard(
            child: _NavRow(
              icon: Icons.language,
              label: 'Time zone',
              value: timeZoneId,
              onTap: onTimeZoneTap,
            ),
          ),
          const _SectionLabel('Guests'),
          _FormCard(
            child: _GuestInput(controller: guestsController),
          ),
          const _SectionLabel('Category'),
          _CategorySelector(
            selected: type,
            onChanged: onTypeChanged,
          ),
          const _SectionLabel('Priority'),
          _PrioritySelector(
            selected: priority,
            onChanged: onPriorityChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _pickStart(BuildContext context) async {
    await pickDateField(
      context: context,
      initial: startAt,
      onPicked: onStartAtChanged,
    );
    if (!allDay && context.mounted) {
      await pickTimeField(
        context: context,
        initial: startAt,
        onPicked: onStartAtChanged,
      );
    }
  }

  Future<void> _pickEnd(BuildContext context) async {
    final now = DateTime.now();
    final initial = endAt ?? startAt.add(const Duration(hours: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 50),
    );
    if (picked == null) return;
    DateTime result = DateTime(picked.year, picked.month, picked.day);
    if (!allDay && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time != null) {
        result = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
      }
    }
    onEndAtChanged(result);
  }
}

// ── Birthday form ────────────────────────────────────────────────────────────

class _BirthdayFormContent extends StatelessWidget {
  const _BirthdayFormContent({
    required this.titleController,
    required this.noteController,
    required this.startAt,
    required this.reminderOffsets,
    required this.onStartAtChanged,
    required this.onRemindersTap,
  });

  final TextEditingController titleController;
  final TextEditingController noteController;
  final DateTime startAt;
  final List<int> reminderOffsets;
  final ValueChanged<DateTime> onStartAtChanged;
  final VoidCallback onRemindersTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTitleField(controller: titleController, hint: "Whose birthday?"),
          const SizedBox(height: AppSpacing.md),
          AppNoteField(controller: noteController),
          const _SectionLabel('Birthday'),
          _FormCard(
            child: _PickerRow(
              icon: Icons.cake_outlined,
              label: 'Month and day',
              value: formatMonthDay(startAt),
              onTap: () async {
                await pickDateField(
                  context: context,
                  initial: startAt,
                  onPicked: onStartAtChanged,
                );
              },
            ),
          ),
          const _SectionLabel('Reminders'),
          _FormCard(
            child: _NavRow(
              icon: Icons.notifications_none,
              label: 'Reminders',
              value: formatReminderSummary(reminderOffsets),
              onTap: onRemindersTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Anniversary form ─────────────────────────────────────────────────────────

class _AnniversaryFormContent extends StatelessWidget {
  const _AnniversaryFormContent({
    required this.titleController,
    required this.noteController,
    required this.startAt,
    required this.reminderOffsets,
    required this.onStartAtChanged,
    required this.onRemindersTap,
  });

  final TextEditingController titleController;
  final TextEditingController noteController;
  final DateTime startAt;
  final List<int> reminderOffsets;
  final ValueChanged<DateTime> onStartAtChanged;
  final VoidCallback onRemindersTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTitleField(controller: titleController, hint: 'Anniversary title'),
          const SizedBox(height: AppSpacing.md),
          AppNoteField(controller: noteController),
          const _SectionLabel('Anniversary'),
          _FormCard(
            child: _PickerRow(
              icon: Icons.favorite_border,
              label: 'Date',
              value: formatDate(startAt),
              onTap: () async {
                await pickDateField(
                  context: context,
                  initial: startAt,
                  onPicked: onStartAtChanged,
                );
              },
            ),
          ),
          const _SectionLabel('Reminders'),
          _FormCard(
            child: _NavRow(
              icon: Icons.notifications_none,
              label: 'Reminders',
              value: formatReminderSummary(reminderOffsets),
              onTap: onRemindersTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Countdown form ───────────────────────────────────────────────────────────

class _CountdownFormContent extends StatelessWidget {
  const _CountdownFormContent({
    required this.titleController,
    required this.noteController,
    required this.startAt,
    required this.onStartAtChanged,
  });

  final TextEditingController titleController;
  final TextEditingController noteController;
  final DateTime startAt;
  final ValueChanged<DateTime> onStartAtChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTitleField(controller: titleController, hint: 'Countdown title'),
          const SizedBox(height: AppSpacing.md),
          AppNoteField(controller: noteController),
          const _SectionLabel('Target date'),
          _FormCard(
            child: _PickerRow(
              icon: Icons.flag_outlined,
              label: 'Target date',
              value: formatDate(startAt),
              onTap: () async {
                await pickDateField(
                  context: context,
                  initial: startAt,
                  onPicked: onStartAtChanged,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reminders picker page ────────────────────────────────────────────────────

class _RemindersPickerPage extends StatefulWidget {
  const _RemindersPickerPage({
    required this.initialOffsets,
    required this.initialTimeOfDayMinutes,
    required this.showAllDayStyle,
  });

  final List<int> initialOffsets;
  final int initialTimeOfDayMinutes;
  final bool showAllDayStyle;

  @override
  State<_RemindersPickerPage> createState() => _RemindersPickerPageState();
}

class _RemindersPickerPageState extends State<_RemindersPickerPage> {
  late final List<int> _offsets;
  late int _timeOfDayMinutes;

  static const List<int> _timedPresets = [0, 5, 10, 15, 30, 60, 120, 1440];
  static const List<int> _dayPresets = [0, 1, 2, 3, 7];

  @override
  void initState() {
    super.initState();
    _offsets = List<int>.from(widget.initialOffsets);
    _timeOfDayMinutes = widget.initialTimeOfDayMinutes;
  }

  List<int> get _presetValues => widget.showAllDayStyle ? _dayPresets : _timedPresets;

  String _presetLabel(int value) {
    if (widget.showAllDayStyle) {
      if (value == 0) return 'On the day';
      if (value == 1) return '1 day before';
      return '$value days before';
    }
    return formatReminderOffset(value);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Reminders', style: AppTypography.sectionTitle(context)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                RemindersPickerResult(
                  offsets: List.unmodifiable(_offsets..sort()),
                  timeOfDayMinutes: _timeOfDayMinutes,
                ),
              );
            },
            child: Text(
              'Done',
              style: AppTypography.bodyMd(context).copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding(context),
        children: [
          if (widget.showAllDayStyle) ...[
            _FormCard(
              child: _PickerRow(
                icon: Icons.access_time,
                label: 'Reminder time',
                value: _formatTimeOfDay(_timeOfDayMinutes),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: _timeOfDayMinutes ~/ 60,
                      minute: _timeOfDayMinutes % 60,
                    ),
                  );
                  if (time != null) {
                    setState(() {
                      _timeOfDayMinutes = time.hour * 60 + time.minute;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const _SectionLabel('Presets'),
          _FormCard(
            child: Column(
              children: _presetValues.map((value) {
                final selected = _offsets.contains(value);
                return _CheckRow(
                  label: _presetLabel(value),
                  selected: selected,
                  onTap: () => _toggle(value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FormCard(
            child: _NavRow(
              icon: Icons.add,
              label: 'Custom reminder',
              value: '',
              onTap: _addCustom,
            ),
          ),
          if (_offsets.any((o) => !_presetValues.contains(o))) ...[
            const _SectionLabel('Custom'),
            _FormCard(
              child: Column(
                children: _offsets
                    .where((o) => !_presetValues.contains(o))
                    .map((o) => _CheckRow(
                          label: formatReminderOffset(o),
                          selected: true,
                          onTap: () => _toggle(o),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggle(int value) {
    setState(() {
      if (_offsets.contains(value)) {
        _offsets.remove(value);
      } else {
        _offsets.add(value);
      }
    });
  }

  Future<void> _addCustom() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => const _CustomReminderDialog(),
    );
    if (result != null) {
      _toggle(result);
    }
  }

  String _formatTimeOfDay(int minutes) {
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return time.format(context);
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMd(context),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded, color: AppColors.accent, size: 22)
              else
                Icon(
                  Icons.check_rounded,
                  color: AppColors.borderFor(brightness),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom reminder dialog ───────────────────────────────────────────────────

class _CustomReminderDialog extends StatefulWidget {
  const _CustomReminderDialog();

  @override
  State<_CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<_CustomReminderDialog> {
  int _value = 15;
  int _unitIndex = 0; // 0 = minutes, 1 = hours, 2 = days

  int get _maxValue => switch (_unitIndex) {
        0 => 60, // minutes
        1 => 24, // hours
        _ => 30, // days
      };

  void _setUnit(int index) {
    setState(() {
      _unitIndex = index;
      if (_value > _maxValue) _value = _maxValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = _maxValue;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Custom reminder', style: AppTypography.sectionTitle(context)),
      content: SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 44,
                magnification: 1.2,
                useMagnifier: true,
                onSelectedItemChanged: (i) => setState(() => _value = i + 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index >= maxValue) return null;
                    return Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.bodyMd(context).copyWith(
                          fontWeight: index + 1 == _value ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                  childCount: maxValue,
                ),
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 44,
                magnification: 1.2,
                useMagnifier: true,
                onSelectedItemChanged: _setUnit,
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    const units = ['minutes', 'hours', 'days'];
                    if (index < 0 || index >= units.length) return null;
                    return Center(
                      child: Text(
                        units[index],
                        style: AppTypography.bodyMd(context).copyWith(
                          fontWeight: index == _unitIndex ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                  childCount: 3,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final multiplier = _unitIndex == 0 ? 1 : _unitIndex == 1 ? 60 : 1440;
            Navigator.of(context).pop(_value * multiplier);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

// ── Repeat picker page ───────────────────────────────────────────────────────

class _RepeatPickerPage extends StatelessWidget {
  const _RepeatPickerPage({required this.initialRule});

  final RepeatRule initialRule;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Repeat', style: AppTypography.sectionTitle(context)),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding(context),
        children: [
          _FormCard(
            child: Column(
              children: RepeatRule.values.map((rule) {
                final selected = rule == initialRule;
                return _CheckRow(
                  label: rule.label,
                  selected: selected,
                  onTap: () => Navigator.of(context).pop(rule),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time zone picker page ────────────────────────────────────────────────────

class _TimeZonePickerPage extends StatefulWidget {
  const _TimeZonePickerPage({required this.initialZone});

  final String initialZone;

  @override
  State<_TimeZonePickerPage> createState() => _TimeZonePickerPageState();
}

class _TimeZonePickerPageState extends State<_TimeZonePickerPage> {
  late final TextEditingController _searchController;
  late List<String> _zones;
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _zones = _buildZoneList();
    _filtered = List<String>.from(_zones);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _buildZoneList() {
    final set = <String>{
      'UTC',
      'GMT',
      'Local',
      'Africa/Nairobi',
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'America/Toronto',
      'America/Sao_Paulo',
      'Europe/London',
      'Europe/Paris',
      'Europe/Berlin',
      'Europe/Moscow',
      'Asia/Dubai',
      'Asia/Kolkata',
      'Asia/Shanghai',
      'Asia/Tokyo',
      'Asia/Seoul',
      'Asia/Singapore',
      'Australia/Sydney',
      'Pacific/Auckland',
    };
    try {
      set.add(DateTime.now().timeZoneName);
    } catch (_) {}
    return set.toList()..sort();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _zones.where((z) => z.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Time zone', style: AppTypography.sectionTitle(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screenPadding(context).copyWith(bottom: AppSpacing.sm),
            child: _FormCard(
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                style: AppTypography.bodyMd(context),
                decoration: InputDecoration(
                  hintText: 'Search time zone',
                  hintStyle: AppTypography.bodyMd(context).copyWith(
                    color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.55),
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.screenPadding(context).copyWith(top: 0),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final zone = _filtered[index];
                final selected = zone == widget.initialZone;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FormCard(
                    child: _CheckRow(
                      label: zone,
                      selected: selected,
                      onTap: () => Navigator.of(context).pop(zone),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
