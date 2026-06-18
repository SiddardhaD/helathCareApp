import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/document_local_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/entities/health_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/usecases/document_usecases.dart';

final documentLocalDataSourceProvider = Provider((ref) => DocumentLocalDataSource());

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(ref.watch(documentLocalDataSourceProvider));
});

final getDocumentsUseCaseProvider =
    Provider((ref) => GetDocumentsUseCase(ref.watch(documentRepositoryProvider)));

final addDocumentUseCaseProvider =
    Provider((ref) => AddDocumentUseCase(ref.watch(documentRepositoryProvider)));

final deleteDocumentUseCaseProvider =
    Provider((ref) => DeleteDocumentUseCase(ref.watch(documentRepositoryProvider)));

final searchDocumentsUseCaseProvider =
    Provider((ref) => SearchDocumentsUseCase(ref.watch(documentRepositoryProvider)));

class DocumentListViewModel extends AsyncNotifier<List<HealthDocument>> {
  @override
  Future<List<HealthDocument>> build() async {
    final result = await ref.read(getDocumentsUseCaseProvider)();
    return result.when(ok: (docs) => docs, err: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Takes a raw picked file path (from camera/gallery/file picker),
  /// persists it to permanent app storage, then saves the document record.
  Future<bool> addDocument({
    required String rawFilePath,
    required String title,
    required DocumentType type,
    List<String> tags = const [],
  }) async {
    final dataSource = ref.read(documentLocalDataSourceProvider);
    final permanentPath = await dataSource.persistFile(rawFilePath);
    final ext = permanentPath.split('.').last;

    final doc = HealthDocument(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      filePath: permanentPath,
      fileExtension: ext,
      type: type,
      tags: tags,
      addedAt: DateTime.now(),
    );

    final result = await ref.read(addDocumentUseCaseProvider)(doc);
    return result.when(
      ok: (_) async {
        await refresh();
        return true;
      },
      err: (_) => Future.value(false),
    );
  }

  Future<bool> deleteDocument(String id) async {
    final result = await ref.read(deleteDocumentUseCaseProvider)(id);
    return result.when(
      ok: (_) async {
        await refresh();
        return true;
      },
      err: (_) => Future.value(false),
    );
  }
}

final documentListViewModelProvider =
    AsyncNotifierProvider<DocumentListViewModel, List<HealthDocument>>(
  DocumentListViewModel.new,
);

/// Separate provider for the search query so the search bar can update it
/// without re-triggering the whole list's AsyncNotifier.
final documentSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredDocumentsProvider = Provider<List<HealthDocument>>((ref) {
  final query = ref.watch(documentSearchQueryProvider);
  final all = ref.watch(documentListViewModelProvider).valueOrNull ?? [];
  if (query.trim().isEmpty) return all;
  final lower = query.toLowerCase();
  return all.where((d) {
    final inTitle = d.title.toLowerCase().contains(lower);
    final inTags = d.tags.any((t) => t.toLowerCase().contains(lower));
    final inType = d.type.name.toLowerCase().contains(lower);
    return inTitle || inTags || inType;
  }).toList();
});
