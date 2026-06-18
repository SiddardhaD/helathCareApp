import '../../../../core/utils/result.dart';
import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<Result<List<Reminder>>> getAll();
  Future<Result<Reminder>> create(Reminder reminder);
  Future<Result<Reminder>> update(Reminder reminder);
  Future<Result<void>> delete(String id);
  Future<Result<Reminder>> toggleCompleted(String id);
}
