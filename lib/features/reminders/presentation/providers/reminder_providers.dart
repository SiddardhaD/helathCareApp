import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/notification_service.dart';
import '../../data/datasources/reminder_local_datasource.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../data/services/reminder_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';

final reminderLocalDataSourceProvider = Provider((ref) => ReminderLocalDataSource());

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(ref.watch(reminderLocalDataSourceProvider));
});

final reminderSchedulerProvider = Provider((ref) {
  return ReminderScheduler(NotificationService.instance);
});

class ReminderListViewModel extends AsyncNotifier<List<Reminder>> {
  final _uuid = const Uuid();

  @override
  Future<List<Reminder>> build() async {
    final result = await ref.read(reminderRepositoryProvider).getAll();
    return result.when(ok: (r) => r, err: (f) => throw f);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<bool> addReminder({
    required String title,
    String? notes,
    required DateTime dateTime,
    ReminderType type = ReminderType.custom,
  }) async {
    final reminder = Reminder(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      dateTime: dateTime,
      type: type,
      createdAt: DateTime.now(),
    );
    final result = await ref.read(reminderRepositoryProvider).create(reminder);
    return result.when(
      ok: (r) async {
        await ref.read(reminderSchedulerProvider).scheduleReminder(r);
        await refresh();
        return true;
      },
      err: (_) => Future.value(false),
    );
  }

  Future<bool> toggleCompleted(String id) async {
    final result = await ref.read(reminderRepositoryProvider).toggleCompleted(id);
    return result.when(
      ok: (r) async {
        if (r.isCompleted) {
          await ref.read(reminderSchedulerProvider).cancelReminder(id);
        } else {
          await ref.read(reminderSchedulerProvider).scheduleReminder(r);
        }
        await refresh();
        return true;
      },
      err: (_) => Future.value(false),
    );
  }

  Future<bool> deleteReminder(String id) async {
    final result = await ref.read(reminderRepositoryProvider).delete(id);
    return result.when(
      ok: (_) async {
        await ref.read(reminderSchedulerProvider).cancelReminder(id);
        await refresh();
        return true;
      },
      err: (_) => Future.value(false),
    );
  }

  List<Reminder> get upcoming {
    final all = state.valueOrNull ?? [];
    return all.where((r) => !r.isCompleted && !r.isPast).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }
}

final reminderListViewModelProvider = AsyncNotifierProvider<ReminderListViewModel, List<Reminder>>(
  ReminderListViewModel.new,
);
