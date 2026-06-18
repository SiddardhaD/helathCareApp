import '../../../../core/utils/result.dart';
import '../entities/medication.dart';

abstract class MedicationRepository {
  Future<Result<List<Medication>>> getAll();

  Future<Result<Medication>> getById(String id);

  Future<Result<Medication>> create(Medication medication);

  Future<Result<Medication>> update(Medication medication);

  Future<Result<void>> delete(String id);

  // Dose logs
  Future<Result<List<DoseLog>>> getDoseLogsForDate(DateTime date);

  Future<Result<DoseLog>> recordDoseAction(String doseLogId, DoseLogStatus status);

  Future<Result<List<DoseLog>>> generateUpcomingLogs({required int daysAhead});
}
