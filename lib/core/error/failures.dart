import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// Clean Architecture rule: data sources throw exceptions, repositories
/// catch them and return [Failure] objects, and the presentation layer only
/// ever deals with [Failure], never raw exceptions. This keeps error
/// handling predictable and testable.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not read or write local data.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item was not found.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission was denied.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something unexpected went wrong.']);
}
