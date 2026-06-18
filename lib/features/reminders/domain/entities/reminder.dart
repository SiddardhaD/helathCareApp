import 'package:equatable/equatable.dart';

enum ReminderType { appointment, refill, custom, followUp }

class Reminder extends Equatable {
  final String id;
  final String title;
  final String? notes;
  final DateTime dateTime;
  final ReminderType type;
  final bool isCompleted;
  final String? linkedMedicationId;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.title,
    this.notes,
    required this.dateTime,
    this.type = ReminderType.custom,
    this.isCompleted = false,
    this.linkedMedicationId,
    required this.createdAt,
  });

  bool get isPast => dateTime.isBefore(DateTime.now());

  bool get isUpcomingSoon =>
      !isCompleted && !isPast && dateTime.difference(DateTime.now()).inHours <= 24;

  Reminder copyWith({
    String? title,
    String? notes,
    DateTime? dateTime,
    ReminderType? type,
    bool? isCompleted,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedMedicationId: linkedMedicationId,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, notes, dateTime, type, isCompleted, linkedMedicationId, createdAt];
}
