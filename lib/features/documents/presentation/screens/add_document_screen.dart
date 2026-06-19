import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/camera_capture_sheet.dart';
import '../../domain/entities/health_document.dart';
import '../providers/document_providers.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  String? _capturedPath;
  DocumentType _type = DocumentType.other;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final path = await CameraCaptureSheet.show(context);
    if (path != null) setState(() => _capturedPath = path);
  }

  Future<void> _save() async {
    if (_capturedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo of the document first.')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give the document a title.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final ok = await ref.read(documentListViewModelProvider.notifier).addDocument(
          rawFilePath: _capturedPath!,
          title: _titleController.text.trim(),
          type: _type,
          tags: tags,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save document. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add document')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CapturedImagePreview(
              path: _capturedPath,
              onTap: _capture,
              onRemove: _capturedPath == null ? null : () => setState(() => _capturedPath = null),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Title', style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Blood test results - June'),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Category', style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: DocumentType.values.map((t) {
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
            Text('Tags', style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(hintText: 'comma, separated, tags (optional)'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(label: 'Save to vault', isLoading: _isSaving, onPressed: _save),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  String _labelFor(DocumentType t) => switch (t) {
        DocumentType.prescription => 'Prescription',
        DocumentType.labResult => 'Lab result',
        DocumentType.insurance => 'Insurance',
        DocumentType.discharge => 'Discharge paper',
        DocumentType.imaging => 'Imaging',
        DocumentType.other => 'Other',
      };
}
