import '../../../../core/utils/result.dart';
import '../entities/health_document.dart';

abstract class DocumentRepository {
  Future<Result<List<HealthDocument>>> getAll();
  Future<Result<HealthDocument>> create(HealthDocument document);
  Future<Result<HealthDocument>> update(HealthDocument document);
  Future<Result<void>> delete(String id);
  Future<Result<List<HealthDocument>>> search(String query);
}
