import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/medication_providers.dart';
import '../widgets/medication_card.dart';
import 'add_edit_medication_screen.dart';
import 'medication_detail_screen.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationListViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Medications')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditMedicationScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load medications: $e')),
        data: (medications) {
          if (medications.isEmpty) {
            return AppEmptyState(
              icon: Icons.medication_outlined,
              title: 'No medications yet',
              message: 'Snap a photo of a prescription or add one manually to get started.',
              actionLabel: 'Add medication',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditMedicationScreen()),
              ),
            );
          }

          final active = medications.where((m) => m.status.name == 'active').toList();
          final other = medications.where((m) => m.status.name != 'active').toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(medicationListViewModelProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (active.isNotEmpty) ...[
                  Text('Active', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ...active.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: MedicationCard(
                          medication: m,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => MedicationDetailScreen(medicationId: m.id)),
                          ),
                        ),
                      )),
                ],
                if (other.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Paused / completed', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ...other.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: MedicationCard(
                          medication: m,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => MedicationDetailScreen(medicationId: m.id)),
                          ),
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
