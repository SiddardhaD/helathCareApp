import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/health_document.dart';
import '../repositories/document_repository.dart';

class GetDocumentsUseCase {
  final DocumentRepository repository;
  const GetDocumentsUseCase(this.repository);

  Future<Result<List<HealthDocument>>> call() => repository.getAll();
}

class AddDocumentUseCase {
  final DocumentRepository repository;
  const AddDocumentUseCase(this.repository);

  Future<Result<HealthDocument>> call(HealthDocument document) async {
    if (document.title.trim().isEmpty) {
      return const Err(ValidationFailure('Document title is required.'));
    }
    return repository.create(document);
  }
}

class UpdateDocumentUseCase {
  final DocumentRepository repository;
  const UpdateDocumentUseCase(this.repository);

  Future<Result<HealthDocument>> call(HealthDocument document) => repository.update(document);
}

class DeleteDocumentUseCase {
  final DocumentRepository repository;
  const DeleteDocumentUseCase(this.repository);

  Future<Result<void>> call(String id) => repository.delete(id);
}

/// Smart-tagging-aware search: matches on title, tags, and document type
/// label, not just title — this is what makes the "smart tagging" feature
/// actually useful when searching the vault.
class SearchDocumentsUseCase {
  final DocumentRepository repository;
  const SearchDocumentsUseCase(this.repository);

  Future<Result<List<HealthDocument>>> call(String query) async {
    if (query.trim().isEmpty) {
      return repository.getAll();
    }
    return repository.search(query.trim());
  }
}
