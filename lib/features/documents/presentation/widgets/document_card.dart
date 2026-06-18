import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/health_document.dart';

class DocumentCard extends StatelessWidget {
  final HealthDocument document;
  final VoidCallback onTap;

  const DocumentCard({super.key, required this.document, required this.onTap});

  IconData get _typeIcon => switch (document.type) {
        DocumentType.prescription => Icons.receipt_long_rounded,
        DocumentType.labResult => Icons.science_outlined,
        DocumentType.insurance => Icons.shield_outlined,
        DocumentType.discharge => Icons.local_hospital_outlined,
        DocumentType.imaging => Icons.image_outlined,
        DocumentType.other => Icons.description_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: document.isImage
                    ? Image.file(File(document.filePath), width: double.infinity, fit: BoxFit.cover)
                    : Container(
                        width: double.infinity,
                        color: AppColors.primaryLighter,
                        child: Icon(_typeIcon, size: 36, color: AppColors.primary),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy').format(document.addedAt),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
