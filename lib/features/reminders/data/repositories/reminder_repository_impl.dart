import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_local_datasource.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderLocalDataSource dataSource;
  ReminderRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Reminder>>> getAll() async {
    try {
      return Ok(await dataSource.getAll());
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<Reminder>> create(Reminder reminder) async {
    try {
      await dataSource.save(reminder);
      return Ok(reminder);
    } catch (_) {
      return const Err(CacheFailure('Could not save reminder.'));
    }
  }

  @override
  Future<Result<Reminder>> update(Reminder reminder) async {
    try {
      await dataSource.save(reminder);
      return Ok(reminder);
    } catch (_) {
      return const Err(CacheFailure('Could not update reminder.'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await dataSource.delete(id);
      return const Ok(null);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }

  @override
  Future<Result<Reminder>> toggleCompleted(String id) async {
    try {
      final existing = await dataSource.getById(id);
      if (existing == null) return const Err(NotFoundFailure('Reminder not found.'));
      final updated = existing.copyWith(isCompleted: !existing.isCompleted);
      await dataSource.save(updated);
      return Ok(updated);
    } catch (_) {
      return const Err(CacheFailure());
    }
  }
}
