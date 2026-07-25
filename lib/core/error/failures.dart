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
  const ServerFailure(
    this.statusCode, [
    super.message = 'Server error',
    this.payload = const ApiFailurePayload(),
  ]);
  final int statusCode;
  final ApiFailurePayload payload;
  String? get errorCode => payload.errorCode;
  Object? get details => payload.details;
  Map<String, dynamic> get metadata => payload.metadata;
}

class ApiFailurePayload {
  const ApiFailurePayload({
    this.errorCode,
    this.details,
    this.metadata = const <String, dynamic>{},
  });

  final String? errorCode;
  final Object? details;
  final Map<String, dynamic> metadata;
}

/// The request conflicts with the current server state (HTTP 409).
class ConflictFailure extends ServerFailure {
  const ConflictFailure([
    String message = 'Request conflict',
    ApiFailurePayload payload = const ApiFailurePayload(),
  ]) : super(409, message, payload);
}

/// The request body is larger than the server accepts (HTTP 413).
class PayloadTooLargeFailure extends ServerFailure {
  const PayloadTooLargeFailure([
    String message = 'Request is too large',
    ApiFailurePayload payload = const ApiFailurePayload(),
  ]) : super(413, message, payload);
}

/// The action is temporarily rate limited (HTTP 429).
class RateLimitFailure extends ServerFailure {
  const RateLimitFailure({
    String message = 'Too many requests',
    this.retryAfter,
    ApiFailurePayload payload = const ApiFailurePayload(),
  }) : super(429, message, payload);

  final Duration? retryAfter;
}

/// The backend is temporarily unable to serve the request (HTTP 503).
class ServiceUnavailableFailure extends ServerFailure {
  const ServiceUnavailableFailure([
    String message = 'Service temporarily unavailable',
    ApiFailurePayload payload = const ApiFailurePayload(),
  ]) : super(503, message, payload);
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
