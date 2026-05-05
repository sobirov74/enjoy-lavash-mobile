/// Base failure type for all error cases in the app.
///
/// Usage:
/// ```dart
/// final result = await repository.getMenu();
/// switch (result) {
///   case Success(:final data): showMenu(data);
///   case Error(:final failure): showError(failure.message);
/// }
/// ```
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No internet or DNS resolution failed.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Server returned a non-2xx status code.
class ServerFailure extends Failure {
  const ServerFailure(this.statusCode, [super.message = 'Server error']);
  final int statusCode;
}

/// Reading/writing local cache failed.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

/// Request took too long.
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

/// Authentication expired or invalid.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

/// Catch-all for unexpected errors.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
