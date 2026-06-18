import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_local_datasource.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationLocalDataSource dataSource;
  final _uuid = const Uuid();

  MedicationRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Medication>>> getAll() async {
    try {
      return Ok(await dataSource.getAll());
    } catch (_) {
      return const Err(CacheFailure('Could not load medications.'));
    }
  }

  @override
  Future<Result<Medication>> getById(String id) async {
    try {
      final med = await dataSource.getById(id);
      if (med == null) return const Err(NotFoundFailure('Medication not found.'));
      return Ok(med);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<Medication>> create(Medication medication) async {
    try {
      await dataSource.save(medication);
      await _regenerateLogsFor(medication, daysAhead: 14);
      return Ok(medication);
    } catch (_) {
      return const Err(CacheFailure('Could not save medication.'));
    }
  }

  @override
  Future<Result<Medication>> update(Medication medication) async {
    try {
      await dataSource.save(medication);
      await _regenerateLogsFor(medication, daysAhead: 14);
      return Ok(medication);
    } catch (_) {
      return const Err(CacheFailure('Could not update medication.'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await dataSource.delete(id);
      return const Ok(null);
    } catch (_) {
      return const Err(CacheFailure('Could not delete medication.'));
    }
  }

  @override
  Future<Result<List<DoseLog>>> getDoseLogsForDate(DateTime date) async {
    try {
      return Ok(await dataSource.getDoseLogsForDate(date));
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<DoseLog>> recordDoseAction(String doseLogId, DoseLogStatus status) async {
    try {
      final existing = await dataSource.getDoseLogById(doseLogId);
      if (existing == null) return const Err(NotFoundFailure('Dose log not found.'));
      final updated = existing.copyWith(status: status, actedAt: DateTime.now());
      await dataSource.saveDoseLog(updated);

      // Decrement pill count on "taken" if tracked.
      if (status == DoseLogStatus.taken) {
        final med = await dataSource.getById(existing.medicationId);
        if (med != null && med.pillsRemaining != null && med.pillsRemaining! > 0) {
          await dataSource.save(med.copyWith(pillsRemaining: med.pillsRemaining! - 1));
        }
      }
      return Ok(updated);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<List<DoseLog>>> generateUpcomingLogs({required int daysAhead}) async {
    try {
      final meds = await dataSource.getAll();
      for (final med in meds) {
        await _regenerateLogsFor(med, daysAhead: daysAhead);
      }
      return Ok(await dataSource.getDoseLogsForDate(DateTime.now()));
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  /// Generates [DoseLog] entries for the given medication for each dose
  /// time over the next [daysAhead] days, skipping any day that already has
  /// a log for that exact scheduled slot (so re-running this doesn't
  /// duplicate or overwrite already-recorded actions).
  Future<void> _regenerateLogsFor(Medication med, {required int daysAhead}) async {
    if (med.status != MedicationStatus.active || med.doseTimes.isEmpty) return;

    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < daysAhead; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      if (med.endDate != null && day.isAfter(med.endDate!)) continue;

      final existingForDay = await dataSource.getDoseLogsForDate(day);
      final existingForMed = existingForDay.where((l) => l.medicationId == med.id).toList();

      for (final doseTime in med.doseTimes) {
        final scheduledFor = DateTime(day.year, day.month, day.day, doseTime.hour, doseTime.minute);
        final alreadyExists = existingForMed.any((l) =>
            l.scheduledFor.hour == scheduledFor.hour && l.scheduledFor.minute == scheduledFor.minute);
        if (alreadyExists) continue;

        await dataSource.saveDoseLog(DoseLog(
          id: _uuid.v4(),
          medicationId: med.id,
          scheduledFor: scheduledFor,
          status: DoseLogStatus.pending,
        ));
      }
    }
  }
}
