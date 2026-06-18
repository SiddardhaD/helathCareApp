import '../../../../core/services/notification_service.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../domain/entities/reminder.dart';

/// Bridges domain entities (Medication, Reminder) to actual scheduled local
/// notifications. Kept as its own service rather than folded into the
/// repositories because scheduling is a side-effecting platform concern,
/// not persistence — this mirrors how the reminders feature is the natural
/// owner of "turn health events into device notifications" regardless of
/// which feature the underlying data came from.
class ReminderScheduler {
  final NotificationService _notifications;

  ReminderScheduler(this._notifications);

  Future<void> scheduleForMedication(Medication medication) async {
    // Clear any previously scheduled doses for this medication's current
    // dose times first, in case they changed (e.g. user edited from 8am to
    // 9am) — re-scheduling overwrites by deterministic id either way, but
    // this also lets a caller explicitly clear stale slots if dose times
    // were removed entirely.
    await cancelKnownDoseTimes(medication.id, medication.doseTimes);

    if (medication.status != MedicationStatus.active) return;

    for (final doseTime in medication.doseTimes) {
      final id = NotificationService.stableIdFromString(
        '${medication.id}_${doseTime.hour}_${doseTime.minute}',
      );
      final foodNote = doseTime.withFood ? ' (take with food)' : '';
      await _notifications.scheduleDaily(
        id: id,
        title: 'Time for ${medication.name}',
        body: '${medication.dosage ?? ''}$foodNote'.trim(),
        hour: doseTime.hour,
        minute: doseTime.minute,
        payload: 'medication:${medication.id}',
      );
    }
  }

  Future<void> cancelKnownDoseTimes(String medicationId, List<DoseTime> doseTimes) async {
    for (final doseTime in doseTimes) {
      final id = NotificationService.stableIdFromString(
        '${medicationId}_${doseTime.hour}_${doseTime.minute}',
      );
      await _notifications.cancel(id);
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (reminder.isCompleted || reminder.isPast) return;
    final id = NotificationService.stableIdFromString('reminder_${reminder.id}');
    await _notifications.scheduleAt(
      id: id,
      title: reminder.title,
      body: reminder.notes ?? _defaultBodyFor(reminder.type),
      dateTime: reminder.dateTime,
      payload: 'reminder:${reminder.id}',
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    final id = NotificationService.stableIdFromString('reminder_$reminderId');
    await _notifications.cancel(id);
  }

  String _defaultBodyFor(ReminderType type) => switch (type) {
        ReminderType.appointment => 'You have an upcoming appointment.',
        ReminderType.refill => 'Time to pick up your refill.',
        ReminderType.followUp => 'Follow-up reminder.',
        ReminderType.custom => 'You have a reminder.',
      };
}
