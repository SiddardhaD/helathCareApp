import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../domain/entities/medication.dart';
import '../providers/medication_providers.dart';
import 'add_edit_medication_screen.dart';
import 'dart:io';

class MedicationDetailScreen extends ConsumerWidget {
  final String medicationId;
  const MedicationDetailScreen({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationListViewModelProvider);

    return medsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (meds) {
        final med = meds.firstWhereOrNull((m) => m.id == medicationId);

        if (med == null) {
          return const Scaffold(body: Center(child: Text('Medication not found.')));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(med.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddEditMedicationScreen(existing: med)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _confirmDelete(context, ref, med),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (med.photoPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.file(
                      File(med.photoPath!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (med.photoPath != null) const SizedBox(height: AppSpacing.md),

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (med.isLowStock)
                      const AppStatusBadge(
                        label: 'Low stock',
                        status: AppBadgeStatus.warning,
                        icon: Icons.inventory_2_outlined,
                      ),
                    if (med.status == MedicationStatus.paused)
                      const AppStatusBadge(label: 'Paused', status: AppBadgeStatus.neutral),
                    if (med.status == MedicationStatus.completed)
                      const AppStatusBadge(label: 'Completed', status: AppBadgeStatus.neutral),
                    if (med.status == MedicationStatus.active)
                      const AppStatusBadge(label: 'Active', status: AppBadgeStatus.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                if (med.doseChanged)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_vert_rounded, color: AppColors.info, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Dose changed from ${med.previousDosage} to ${med.dosage ?? "—"}',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                _DetailSection(
                  title: 'Details',
                  rows: [
                    _DetailRow('Dosage', med.dosage ?? '—'),
                    _DetailRow('Form', med.form ?? '—'),
                    _DetailRow('Prescribed by', med.prescribedBy ?? '—'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                if (med.doseTimes.isNotEmpty)
                  _DetailSection(
                    title: 'Schedule',
                    rows: med.doseTimes
                        .map((d) => _DetailRow(d.label, d.withFood ? 'With food' : 'Any time'))
                        .toList(),
                  ),
                const SizedBox(height: AppSpacing.md),

                if (med.pillsRemaining != null || med.totalPillsPerRefill != null)
                  _DetailSection(
                    title: 'Supply',
                    rows: [
                      _DetailRow('Pills remaining', med.pillsRemaining?.toString() ?? '—'),
                      _DetailRow('Pills per refill', med.totalPillsPerRefill?.toString() ?? '—'),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),

                if (med.notes != null && med.notes!.isNotEmpty)
                  _DetailSection(title: 'Notes', rows: [_DetailRow('', med.notes!)]),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Medication med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medication?'),
        content: Text('This will remove ${med.name} and its scheduled reminders.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(medicationListViewModelProvider.notifier).deleteMedication(med.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.critical)),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailRow> rows;
  const _DetailSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: r.label.isEmpty
                    ? Text(r.value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(r.label, style: AppTextStyles.bodyMedium),
                          ),
                          Expanded(
                            child: Text(
                              r.value,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
              )),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}
