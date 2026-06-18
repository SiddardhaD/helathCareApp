import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../domain/entities/medication.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;

  const MedicationCard({super.key, required this.medication, required this.onTap});

  Color get _tagColor {
    try {
      return Color(int.parse(medication.colorTag.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _tagColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.medication_rounded, color: _tagColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    [medication.dosage, medication.form]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' • '),
                    style: AppTextStyles.bodySmall,
                  ),
                  if (medication.doseTimes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      medication.doseTimes.map((d) => d.label).join(', '),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (medication.isLowStock)
                  const AppStatusBadge(
                    label: 'Low stock',
                    status: AppBadgeStatus.warning,
                    icon: Icons.inventory_2_outlined,
                  )
                else if (medication.status == MedicationStatus.paused)
                  const AppStatusBadge(label: 'Paused', status: AppBadgeStatus.neutral)
                else if (medication.doseChanged)
                  const AppStatusBadge(
                    label: 'Dose changed',
                    status: AppBadgeStatus.info,
                    icon: Icons.swap_vert_rounded,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
