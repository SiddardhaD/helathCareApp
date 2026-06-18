import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/health_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource dataSource;
  DocumentRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<HealthDocument>>> getAll() async {
    try {
      return Ok(await dataSource.getAll());
    } catch (_) {
      return const Err(CacheFailure('Could not load documents.'));
    }
  }

  @override
  Future<Result<HealthDocument>> create(HealthDocument document) async {
    try {
      await dataSource.save(document);
      return Ok(document);
    } catch (_) {
      return const Err(CacheFailure('Could not save document.'));
    }
  }

  @override
  Future<Result<HealthDocument>> update(HealthDocument document) async {
    try {
      await dataSource.save(document);
      return Ok(document);
    } catch (_) {
      return const Err(CacheFailure('Could not update document.'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await dataSource.delete(id);
      return const Ok(null);
    } catch (_) {
      return const Err(CacheFailure('Could not delete document.'));
    }
  }

  @override
  Future<Result<List<HealthDocument>>> search(String query) async {
    try {
      return Ok(await dataSource.search(query));
    } catch (_) {
      return const Err(CacheFailure());
    }
  }
}
