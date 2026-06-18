import 'package:hive/hive.dart';

import '../../domain/entities/reminder.dart';

class ReminderLocalDataSource {
  static const _boxName = 'reminders';

  Box get _box => Hive.box(_boxName);

  static Future<void> ensureBoxOpen() async {
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
  }

  Future<List<Reminder>> getAll() async {
    return _box.values.map((raw) => _decode(Map<String, dynamic>.from(raw as Map))).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<Reminder?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _decode(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> save(Reminder reminder) async {
    await _box.put(reminder.id, _encode(reminder));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Map<String, dynamic> _encode(Reminder r) => {
        'id': r.id,
        'title': r.title,
        'notes': r.notes,
        'dateTime': r.dateTime.toIso8601String(),
        'type': r.type.name,
        'isCompleted': r.isCompleted,
        'linkedMedicationId': r.linkedMedicationId,
        'createdAt': r.createdAt.toIso8601String(),
      };

  Reminder _decode(Map<String, dynamic> m) => Reminder(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: m['notes'] as String?,
        dateTime: DateTime.parse(m['dateTime'] as String),
        type: ReminderType.values.firstWhere((t) => t.name == m['type']),
        isCompleted: (m['isCompleted'] as bool?) ?? false,
        linkedMedicationId: m['linkedMedicationId'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
