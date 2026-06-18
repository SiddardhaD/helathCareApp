import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetMedicationsUseCase {
  final MedicationRepository repository;
  const GetMedicationsUseCase(this.repository);

  Future<Result<List<Medication>>> call() => repository.getAll();
}

class AddMedicationUseCase {
  final MedicationRepository repository;
  const AddMedicationUseCase(this.repository);

  Future<Result<Medication>> call(Medication medication) async {
    if (medication.name.trim().isEmpty) {
      return const Err(ValidationFailure('Medication name is required.'));
    }
    return repository.create(medication);
  }
}

/// Encapsulates the "what changed" business rule: when a medication is
/// edited and the dosage differs from before, we record the prior dosage so
/// the UI can surface a plain-language diff ("dose increased from 10mg to
/// 20mg"). This logic belongs here, not in the ViewModel, because it's a
/// domain rule about what counts as a meaningful change worth flagging.
class UpdateMedicationUseCase {
  final MedicationRepository repository;
  const UpdateMedicationUseCase(this.repository);

  Future<Result<Medication>> call(Medication updated, {Medication? previous}) async {
    if (updated.name.trim().isEmpty) {
      return const Err(ValidationFailure('Medication name is required.'));
    }

    final dosageChanged = previous != null && previous.dosage != updated.dosage;
    final toSave = dosageChanged ? updated.copyWith(previousDosage: previous!.dosage) : updated;

    return repository.update(toSave);
  }
}

class DeleteMedicationUseCase {
  final MedicationRepository repository;
  const DeleteMedicationUseCase(this.repository);

  Future<Result<void>> call(String id) => repository.delete(id);
}

class RecordDoseActionUseCase {
  final MedicationRepository repository;
  const RecordDoseActionUseCase(this.repository);

  Future<Result<DoseLog>> call(String doseLogId, DoseLogStatus status) =>
      repository.recordDoseAction(doseLogId, status);
}

class GetTodayDoseLogsUseCase {
  final MedicationRepository repository;
  const GetTodayDoseLogsUseCase(this.repository);

  Future<Result<List<DoseLog>>> call() => repository.getDoseLogsForDate(DateTime.now());
}

/// Pure domain-rule helper (no I/O) for low-stock detection, kept separate
/// from the entity's own [Medication.isLowStock] getter so more complex
/// rules (e.g. factoring in days-until-refill-possible) can be added later
/// without touching the entity.
class CheckLowStockUseCase {
  const CheckLowStockUseCase();

  List<Medication> call(List<Medication> medications) {
    return medications.where((m) => m.status == MedicationStatus.active && m.isLowStock).toList();
  }
}
