import 'failures.dart';

/// Lightweight Result type — no external dependencies.
///
/// ```dart
/// final result = await repo.getProducts();
/// switch (result) {
///   case Success(:final data): return data;
///   case Error(:final failure): showError(failure.message);
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Successful result containing [data].
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

/// Failed result containing a [Failure].
final class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}

/// Convenience constructors.
extension ResultOf on Never {
  static Result<T> success<T>(T data) => Success(data);
  static Result<T> error<T>(Failure failure) => Error(failure);
}

/// Helpers on `Result<T>`.
extension ResultX<T> on Result<T> {
  /// Get data or null.
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Error() => null,
  };

  /// Get failure or null.
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Error(:final failure) => failure,
  };

  /// True if this is a Success.
  bool get isSuccess => this is Success<T>;

  /// True if this is an Error.
  bool get isError => this is Error<T>;

  /// Transform the success data.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success(:final data) => Success(transform(data)),
    Error(:final failure) => Error(failure),
  };

  /// Handle both cases.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) => switch (this) {
    Success(:final data) => success(data),
    Error(:final failure) => error(failure),
  };
}
