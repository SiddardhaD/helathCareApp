import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/camera_capture_sheet.dart';
import '../../domain/entities/medication.dart';
import '../providers/medication_providers.dart';

class AddEditMedicationScreen extends ConsumerStatefulWidget {
  final Medication? existing;
  const AddEditMedicationScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditMedicationScreen> createState() => _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState extends ConsumerState<AddEditMedicationScreen> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _dosageController = TextEditingController(text: widget.existing?.dosage ?? '');
  late final _formController = TextEditingController(text: widget.existing?.form ?? '');
  late final _prescribedByController = TextEditingController(text: widget.existing?.prescribedBy ?? '');
  late final _notesController = TextEditingController(text: widget.existing?.notes ?? '');
  late final _pillsRemainingController =
      TextEditingController(text: widget.existing?.pillsRemaining?.toString() ?? '');
  late final _totalPillsController =
      TextEditingController(text: widget.existing?.totalPillsPerRefill?.toString() ?? '');

  late String? _photoPath = widget.existing?.photoPath;
  late List<DoseTime> _doseTimes = List.of(widget.existing?.doseTimes ?? const [DoseTime(hour: 8, minute: 0)]);
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _formController.dispose();
    _prescribedByController.dispose();
    _notesController.dispose();
    _pillsRemainingController.dispose();
    _totalPillsController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final path = await CameraCaptureSheet.show(context);
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _addDoseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (time == null) return;
    setState(() => _doseTimes = [..._doseTimes, DoseTime(hour: time.hour, minute: time.minute)]);
  }

  void _removeDoseTime(int index) {
    setState(() => _doseTimes = [..._doseTimes]..removeAt(index));
  }

  void _toggleWithFood(int index) {
    setState(() {
      final updated = [..._doseTimes];
      final dt = updated[index];
      updated[index] = DoseTime(hour: dt.hour, minute: dt.minute, withFood: !dt.withFood);
      _doseTimes = updated;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medication name.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final vm = ref.read(medicationListViewModelProvider.notifier);

    final medication = Medication(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
      form: _formController.text.trim().isEmpty ? null : _formController.text.trim(),
      prescribedBy: _prescribedByController.text.trim().isEmpty ? null : _prescribedByController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      photoPath: _photoPath,
      doseTimes: _doseTimes,
      status: widget.existing?.status ?? MedicationStatus.active,
      startDate: widget.existing?.startDate ?? now,
      pillsRemaining: int.tryParse(_pillsRemainingController.text.trim()),
      totalPillsPerRefill: int.tryParse(_totalPillsController.text.trim()),
      colorTag: widget.existing?.colorTag ??
          ('#${AppColors.doseTagColors[now.millisecond % AppColors.doseTagColors.length].value.toRadixString(16).substring(2)}'),
      previousDosage: widget.existing?.previousDosage,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final result = _isEditing
        ? await vm.updateMedication(medication, previous: widget.existing)
        : await vm.addMedication(medication);

    if (mounted) {
      setState(() => _isSaving = false);
      if (result != null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save medication. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit medication' : 'Add medication')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CapturedImagePreview(
              path: _photoPath,
              onTap: _capturePhoto,
              onRemove: _photoPath == null ? null : () => setState(() => _photoPath = null),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Label('Medication name'),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. Lisinopril')),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Dosage'),
                      TextField(controller: _dosageController, decoration: const InputDecoration(hintText: 'e.g. 10mg')),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Form'),
                      TextField(controller: _formController, decoration: const InputDecoration(hintText: 'e.g. Tablet')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Label('Prescribed by'),
            TextField(controller: _prescribedByController, decoration: const InputDecoration(hintText: 'Dr. name (optional)')),
            const SizedBox(height: AppSpacing.lg),
            _Label('Dose schedule'),
            const SizedBox(height: AppSpacing.sm),
            ..._doseTimes.asMap().entries.map((entry) {
              final index = entry.key;
              final dt = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(dt.label, style: AppTextStyles.bodyLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _toggleWithFood(index),
                        icon: Icon(
                          dt.withFood ? Icons.restaurant_rounded : Icons.restaurant_outlined,
                          size: 16,
                        ),
                        label: Text(dt.withFood ? 'With food' : 'Any time', style: AppTextStyles.bodySmall),
                      ),
                      IconButton(
                        onPressed: () => _removeDoseTime(index),
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addDoseTime,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add a dose time'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Label('Pill tracking (optional)'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pillsRemainingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Pills remaining'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _totalPillsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Pills per refill'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Label('Notes'),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Anything else worth remembering'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: _isEditing ? 'Save changes' : 'Add medication',
              isLoading: _isSaving,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.labelMedium),
    );
  }
}
