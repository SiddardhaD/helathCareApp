import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(reminderListViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load reminders: $e')),
        data: (reminders) {
          if (reminders.isEmpty) {
            return AppEmptyState(
              icon: Icons.notifications_active_outlined,
              title: 'No reminders yet',
              message: 'Add reminders for appointments, refills, or anything else health-related.',
              actionLabel: 'Add reminder',
              onAction: () => _showAddReminderSheet(context, ref),
            );
          }

          final sorted = [...reminders]..sort((a, b) {
              if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
              return a.dateTime.compareTo(b.dateTime);
            });

          return RefreshIndicator(
            onRefresh: () => ref.read(reminderListViewModelProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _ReminderTile(reminder: sorted[index]),
            ),
          );
        },
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderTile({required this.reminder});

  IconData get _icon => switch (reminder.type) {
        ReminderType.appointment => Icons.event_available_rounded,
        ReminderType.refill => Icons.medication_liquid_rounded,
        ReminderType.followUp => Icons.replay_rounded,
        ReminderType.custom => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(reminderListViewModelProvider.notifier);
    final dateLabel = DateFormat('EEE, MMM d • h:mm a').format(reminder.dateTime);

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.criticalLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.critical),
      ),
      onDismissed: (_) => vm.deleteReminder(reminder.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          leading: Checkbox(
            value: reminder.isCompleted,
            activeColor: AppColors.primary,
            onChanged: (_) => vm.toggleCompleted(reminder.id),
          ),
          title: Text(
            reminder.title,
            style: AppTextStyles.titleMedium.copyWith(
              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              color: reminder.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Icon(_icon, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(dateLabel, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet();

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));
  ReminderType _type = ReminderType.appointment;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final ok = await ref.read(reminderListViewModelProvider.notifier).addReminder(
          title: _titleController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          dateTime: _dateTime,
          type: _type,
        );
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('New reminder', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Cardiologist appointment'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(hintText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ReminderType.values.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(_labelFor(t)),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = t),
                  selectedColor: AppColors.primaryLight,
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      DateFormat('EEE, MMM d, yyyy • h:mm a').format(_dateTime),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(label: 'Save reminder', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }

  String _labelFor(ReminderType t) => switch (t) {
        ReminderType.appointment => 'Appointment',
        ReminderType.refill => 'Refill',
        ReminderType.followUp => 'Follow-up',
        ReminderType.custom => 'Other',
      };
}
