import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/medication_local_datasource.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/usecases/medication_usecases.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';

final medicationLocalDataSourceProvider = Provider((ref) => MedicationLocalDataSource());

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(ref.watch(medicationLocalDataSourceProvider));
});

final getMedicationsUseCaseProvider =
    Provider((ref) => GetMedicationsUseCase(ref.watch(medicationRepositoryProvider)));

final addMedicationUseCaseProvider =
    Provider((ref) => AddMedicationUseCase(ref.watch(medicationRepositoryProvider)));

final updateMedicationUseCaseProvider =
    Provider((ref) => UpdateMedicationUseCase(ref.watch(medicationRepositoryProvider)));

final deleteMedicationUseCaseProvider =
    Provider((ref) => DeleteMedicationUseCase(ref.watch(medicationRepositoryProvider)));

final recordDoseActionUseCaseProvider =
    Provider((ref) => RecordDoseActionUseCase(ref.watch(medicationRepositoryProvider)));

final getTodayDoseLogsUseCaseProvider =
    Provider((ref) => GetTodayDoseLogsUseCase(ref.watch(medicationRepositoryProvider)));

const checkLowStockUseCase = CheckLowStockUseCase();

/// ViewModel holding the full medications list. AsyncNotifier gives us
/// loading/error/data states for free and a clean `refresh()` for pull to
/// refresh / after add-edit-delete actions.
class MedicationListViewModel extends AsyncNotifier<List<Medication>> {
  @override
  Future<List<Medication>> build() async {
    final result = await ref.read(getMedicationsUseCaseProvider)();
    return result.when(ok: (meds) => meds, err: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Medication?> addMedication(Medication medication) async {
    final result = await ref.read(addMedicationUseCaseProvider)(medication);
    return result.when(
      ok: (med) async {
        await refresh();
        // Schedule local notifications for the newly added medication's doses.
        await ref.read(reminderSchedulerProvider).scheduleForMedication(med);
        return med;
      },
      err: (_) => Future.value(null),
    );
  }

  Future<Medication?> updateMedication(Medication updated, {Medication? previous}) async {
    final result = await ref.read(updateMedicationUseCaseProvider)(updated, previous: previous);
    return result.when(
      ok: (med) async {
        await refresh();
        await ref.read(reminderSchedulerProvider).scheduleForMedication(med);
        return med;
      },
      err: (_) => Future.value(null),
    );
  }

  Future<bool> deleteMedication(String id) async {
    final existing = (state.valueOrNull ?? []).where((m) => m.id == id).firstOrNull;
    final result = await ref.read(deleteMedicationUseCaseProvider)(id);
    return result.when(
      ok: (_) async {
        if (existing != null) {
          await ref.read(reminderSchedulerProvider).cancelKnownDoseTimes(id, existing.doseTimes);
        }
        await refresh();
        return true;
      },
      err: (_) => Future.value(false),
    );
  }

  List<Medication> get lowStockMedications {
    final meds = state.valueOrNull ?? [];
    return checkLowStockUseCase(meds);
  }
}

final medicationListViewModelProvider =
    AsyncNotifierProvider<MedicationListViewModel, List<Medication>>(
  MedicationListViewModel.new,
);

/// Today's dose logs joined with their medication, for the home/dashboard
/// "what's due today" view.
class TodayDoseLog {
  final DoseLog log;
  final Medication medication;
  const TodayDoseLog(this.log, this.medication);
}

final todayDoseLogsProvider = FutureProvider<List<TodayDoseLog>>((ref) async {
  final medsResult = await ref.read(getMedicationsUseCaseProvider)();
  final logsResult = await ref.read(getTodayDoseLogsUseCaseProvider)();

  final meds = medsResult.valueOrNull ?? [];
  final logs = logsResult.valueOrNull ?? [];

  final medsById = {for (final m in meds) m.id: m};

  return logs
      .where((l) => medsById.containsKey(l.medicationId))
      .map((l) => TodayDoseLog(l, medsById[l.medicationId]!))
      .toList()
    ..sort((a, b) => a.log.scheduledFor.compareTo(b.log.scheduledFor));
});
