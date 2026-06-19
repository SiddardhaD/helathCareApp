
import 'package:health_companion/core/error/failures.dart';

/// A minimal Result type representing either success ([Ok]) or failure
/// ([Err]). This avoids pulling in a heavier functional-programming package
/// like dartz just for Either, while still giving repositories and use
/// cases a clean way to propagate failures without throwing.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Returns the success value or null.
  T? get valueOrNull => switch (this) {
        Ok<T>(value: final v) => v,
        Err<T>() => null,
      };

  /// Returns the failure or null.
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(failure: final f) => f,
      };

  /// Pattern-match helper for handling both branches concisely in the UI.
  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) {
    return switch (this) {
      Ok<T>(value: final v) => ok(v),
      Err<T>(failure: final f) => err(f),
    };
  }
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
