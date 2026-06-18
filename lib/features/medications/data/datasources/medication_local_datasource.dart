import 'package:hive/hive.dart';

import '../../domain/entities/medication.dart';

/// Local data source for medications, backed by Hive.
///
/// Deliberately uses manual Map<->Medication conversion instead of
/// Hive's generated TypeAdapters. This avoids a build_runner codegen step
/// (which can't be run in every environment) while keeping the same clean
/// separation: this class is the only place that knows about Hive at all.
class MedicationLocalDataSource {
  static const _boxName = 'medications';
  static const _doseLogBoxName = 'dose_logs';

  Box get _box => Hive.box(_boxName);
  Box get _doseLogBox => Hive.box(_doseLogBoxName);

  static Future<void> ensureBoxesOpen() async {
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
    if (!Hive.isBoxOpen(_doseLogBoxName)) await Hive.openBox(_doseLogBoxName);
  }

  Future<List<Medication>> getAll() async {
    return _box.values
        .map((raw) => _decode(Map<String, dynamic>.from(raw as Map)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Medication?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _decode(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> save(Medication medication) async {
    await _box.put(medication.id, _encode(medication));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    // Also remove dose logs tied to this medication to avoid orphaned data.
    final keysToRemove = _doseLogBox.keys.where((k) {
      final raw = _doseLogBox.get(k);
      if (raw == null) return false;
      final map = Map<String, dynamic>.from(raw as Map);
      return map['medicationId'] == id;
    }).toList();
    await _doseLogBox.deleteAll(keysToRemove);
  }

  // ---- Dose logs ----

  Future<List<DoseLog>> getDoseLogsForDate(DateTime date) async {
    final all = _doseLogBox.values
        .map((raw) => _decodeDoseLog(Map<String, dynamic>.from(raw as Map)))
        .toList();
    return all.where((log) =>
        log.scheduledFor.year == date.year &&
        log.scheduledFor.month == date.month &&
        log.scheduledFor.day == date.day).toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  Future<DoseLog?> getDoseLogById(String id) async {
    final raw = _doseLogBox.get(id);
    if (raw == null) return null;
    return _decodeDoseLog(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> saveDoseLog(DoseLog log) async {
    await _doseLogBox.put(log.id, _encodeDoseLog(log));
  }

  Future<bool> hasLogsForDate(DateTime date) async {
    final logs = await getDoseLogsForDate(date);
    return logs.isNotEmpty;
  }

  // ---- Encoding helpers ----

  Map<String, dynamic> _encode(Medication m) => {
        'id': m.id,
        'name': m.name,
        'dosage': m.dosage,
        'form': m.form,
        'prescribedBy': m.prescribedBy,
        'notes': m.notes,
        'photoPath': m.photoPath,
        'doseTimes': m.doseTimes.map((d) => d.toMap()).toList(),
        'frequency': m.frequency.name,
        'status': m.status.name,
        'startDate': m.startDate.toIso8601String(),
        'endDate': m.endDate?.toIso8601String(),
        'pillsRemaining': m.pillsRemaining,
        'totalPillsPerRefill': m.totalPillsPerRefill,
        'colorTag': m.colorTag,
        'previousDosage': m.previousDosage,
        'createdAt': m.createdAt.toIso8601String(),
        'updatedAt': m.updatedAt.toIso8601String(),
      };

  Medication _decode(Map<String, dynamic> m) => Medication(
        id: m['id'] as String,
        name: m['name'] as String,
        dosage: m['dosage'] as String?,
        form: m['form'] as String?,
        prescribedBy: m['prescribedBy'] as String?,
        notes: m['notes'] as String?,
        photoPath: m['photoPath'] as String?,
        doseTimes: (m['doseTimes'] as List? ?? [])
            .map((d) => DoseTime.fromMap(Map<String, dynamic>.from(d as Map)))
            .toList(),
        frequency: DoseFrequency.values.firstWhere((f) => f.name == m['frequency']),
        status: MedicationStatus.values.firstWhere((s) => s.name == m['status']),
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: m['endDate'] != null ? DateTime.parse(m['endDate'] as String) : null,
        pillsRemaining: m['pillsRemaining'] as int?,
        totalPillsPerRefill: m['totalPillsPerRefill'] as int?,
        colorTag: m['colorTag'] as String,
        previousDosage: m['previousDosage'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  Map<String, dynamic> _encodeDoseLog(DoseLog d) => {
        'id': d.id,
        'medicationId': d.medicationId,
        'scheduledFor': d.scheduledFor.toIso8601String(),
        'actedAt': d.actedAt?.toIso8601String(),
        'status': d.status.name,
      };

  DoseLog _decodeDoseLog(Map<String, dynamic> m) => DoseLog(
        id: m['id'] as String,
        medicationId: m['medicationId'] as String,
        scheduledFor: DateTime.parse(m['scheduledFor'] as String),
        actedAt: m['actedAt'] != null ? DateTime.parse(m['actedAt'] as String) : null,
        status: DoseLogStatus.values.firstWhere((s) => s.name == m['status']),
      );
}
