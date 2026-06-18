import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Bottom sheet offering "Take photo" / "Choose from gallery", returning the
/// picked file path or null if cancelled. Shared by medications (snap a
/// prescription label) and documents (snap a receipt, insurance card, etc.)
/// so the capture UX is identical everywhere in the app.
class CameraCaptureSheet {
  static Future<String?> show(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SourcePickerSheet(),
    );
    if (source == null) return null;

    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: source, imageQuality: 85);
      return file?.path;
    } catch (_) {
      return null;
    }
  }
}

class _SourcePickerSheet extends StatelessWidget {
  const _SourcePickerSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Add a photo', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          _OptionTile(
            icon: Icons.camera_alt_rounded,
            label: 'Take photo',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionTile(
            icon: Icons.photo_library_rounded,
            label: 'Choose from gallery',
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}

/// Thumbnail preview for a captured/selected image, with a remove button.
/// Reused in add/edit forms across medications and documents.
class CapturedImagePreview extends StatelessWidget {
  final String? path;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const CapturedImagePreview({super.key, required this.path, required this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 28),
              SizedBox(height: 8),
              Text('Add photo of label or document', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: GestureDetector(
            onTap: onTap,
            child: Image.file(
              File(path!),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}
