import 'package:equatable/equatable.dart';

enum DoseFrequency { daily, weekly, asNeeded }

enum MedicationStatus { active, paused, completed }

/// A specific time of day a dose should be taken, stored as minutes from
/// midnight so it's trivial to schedule local notifications against it
/// regardless of locale/date.
class DoseTime extends Equatable {
  final int hour; // 0-23
  final int minute; // 0-59
  final bool withFood;

  const DoseTime({required this.hour, required this.minute, this.withFood = false});

  String get label {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Map<String, dynamic> toMap() => {'hour': hour, 'minute': minute, 'withFood': withFood};

  factory DoseTime.fromMap(Map<dynamic, dynamic> m) => DoseTime(
        hour: m['hour'] as int,
        minute: m['minute'] as int,
        withFood: (m['withFood'] as bool?) ?? false,
      );

  @override
  List<Object?> get props => [hour, minute, withFood];
}

class Medication extends Equatable {
  final String id;
  final String name;
  final String? dosage; // e.g. "20mg"
  final String? form; // e.g. "tablet", "capsule", "liquid"
  final String? prescribedBy;
  final String? notes;
  final String? photoPath; // local path to photographed prescription/label
  final List<DoseTime> doseTimes;
  final DoseFrequency frequency;
  final MedicationStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final int? pillsRemaining;
  final int? totalPillsPerRefill;
  final String colorTag; // hex string, used for visual differentiation
  final String? previousDosage; // tracks last known dose for "what changed"
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    required this.name,
    this.dosage,
    this.form,
    this.prescribedBy,
    this.notes,
    this.photoPath,
    this.doseTimes = const [],
    this.frequency = DoseFrequency.daily,
    this.status = MedicationStatus.active,
    required this.startDate,
    this.endDate,
    this.pillsRemaining,
    this.totalPillsPerRefill,
    required this.colorTag,
    this.previousDosage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock =>
      pillsRemaining != null && totalPillsPerRefill != null && totalPillsPerRefill! > 0
          ? pillsRemaining! / totalPillsPerRefill! <= 0.15
          : (pillsRemaining != null && pillsRemaining! <= 5);

  bool get doseChanged => previousDosage != null && previousDosage != dosage;

  Medication copyWith({
    String? name,
    String? dosage,
    String? form,
    String? prescribedBy,
    String? notes,
    String? photoPath,
    List<DoseTime>? doseTimes,
    DoseFrequency? frequency,
    MedicationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? pillsRemaining,
    int? totalPillsPerRefill,
    String? colorTag,
    String? previousDosage,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      doseTimes: doseTimes ?? this.doseTimes,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pillsRemaining: pillsRemaining ?? this.pillsRemaining,
      totalPillsPerRefill: totalPillsPerRefill ?? this.totalPillsPerRefill,
      colorTag: colorTag ?? this.colorTag,
      previousDosage: previousDosage ?? this.previousDosage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        dosage,
        form,
        prescribedBy,
        notes,
        photoPath,
        doseTimes,
        frequency,
        status,
        startDate,
        endDate,
        pillsRemaining,
        totalPillsPerRefill,
        colorTag,
        previousDosage,
        createdAt,
        updatedAt,
      ];
}

/// A logged event for a specific dose at a specific time — the building
/// block for adherence tracking, the side-effect journal, and the "what's
/// due today" home screen view.
enum DoseLogStatus { taken, missed, skipped, pending }

class DoseLog extends Equatable {
  final String id;
  final String medicationId;
  final DateTime scheduledFor;
  final DateTime? actedAt;
  final DoseLogStatus status;

  const DoseLog({
    required this.id,
    required this.medicationId,
    required this.scheduledFor,
    this.actedAt,
    this.status = DoseLogStatus.pending,
  });

  DoseLog copyWith({DateTime? actedAt, DoseLogStatus? status}) => DoseLog(
        id: id,
        medicationId: medicationId,
        scheduledFor: scheduledFor,
        actedAt: actedAt ?? this.actedAt,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [id, medicationId, scheduledFor, actedAt, status];
}
