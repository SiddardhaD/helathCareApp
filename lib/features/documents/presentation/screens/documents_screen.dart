import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/document_providers.dart';
import '../widgets/document_card.dart';
import 'add_document_screen.dart';
import 'document_viewer_screen.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListViewModelProvider);
    final filtered = ref.watch(filteredDocumentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Document vault')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddDocumentScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load documents: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return AppEmptyState(
              icon: Icons.folder_open_outlined,
              title: 'Your vault is empty',
              message: 'Snap a photo of prescriptions, lab results, or insurance cards to keep them all in one place.',
              actionLabel: 'Add document',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddDocumentScreen()),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search documents, tags, categories',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => ref.read(documentSearchQueryProvider.notifier).state = v,
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No documents match your search.'))
                    : RefreshIndicator(
                        onRefresh: () => ref.read(documentListViewModelProvider.notifier).refresh(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AppSpacing.sm,
                            crossAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            return DocumentCard(
                              document: doc,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: doc)),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
