import 'dart:io';

import 'package:dio/dio.dart';
import 'failures.dart';
import 'mobile_error_messages.dart';

/// Maps a [DioException] to a typed [Failure].
Failure mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();

    case DioExceptionType.connectionError:
      return const NetworkFailure();

    case DioExceptionType.badResponse:
      final status = e.response?.statusCode ?? 0;
      final serverMessage = resolveApiErrorMessage(
        data: e.response?.data,
        statusCode: status,
        languageCode: _requestLanguage(e),
      );
      final payload = _failurePayload(e.response?.data);
      final failurePayload = ApiFailurePayload(
        errorCode: payload.errorCode,
        details: payload.details,
        metadata: payload.metadata,
      );
      if (status == 401) {
        return AuthFailure(serverMessage);
      }
      return switch (status) {
        409 => ConflictFailure(serverMessage, failurePayload),
        413 => PayloadTooLargeFailure(serverMessage, failurePayload),
        429 => RateLimitFailure(
          message: serverMessage,
          retryAfter: _retryAfter(e),
          payload: failurePayload,
        ),
        503 => ServiceUnavailableFailure(serverMessage, failurePayload),
        _ => ServerFailure(status, serverMessage, failurePayload),
      };

    case DioExceptionType.cancel:
      return const UnknownFailure('Request cancelled');

    case DioExceptionType.badCertificate:
      return const NetworkFailure('Certificate error');

    case DioExceptionType.unknown:
      if (e.error is SocketException) {
        return const NetworkFailure();
      }
      return UnknownFailure(e.message ?? 'Unknown error');
  }
}

({String? errorCode, Object? details, Map<String, dynamic> metadata})
_failurePayload(Object? data) {
  if (data is! Map) {
    return (
      errorCode: null,
      details: null,
      metadata: const <String, dynamic>{},
    );
  }
  final map = Map<String, dynamic>.from(data);
  final metadataValue = map['metadata'];
  final metadata = metadataValue is Map
      ? Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(metadataValue),
        )
      : const <String, dynamic>{};
  final rawCode = map['errorCode'] ?? map['error_code'];
  final errorCode = rawCode?.toString().trim();
  return (
    errorCode: errorCode?.isEmpty == true ? null : errorCode,
    details: map['details'],
    metadata: metadata,
  );
}

Duration? _retryAfter(DioException error) {
  final header = error.response?.headers.value('retry-after')?.trim();
  final fromHeader = _retryAfterValue(header);
  if (fromHeader != null) return fromHeader;

  final data = error.response?.data;
  if (data is Map) {
    for (final key in const [
      'retryAfter',
      'retry_after',
      'retryAfterSeconds',
      'retry_after_seconds',
    ]) {
      final parsed = _retryAfterValue(data[key]);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

Duration? _retryAfterValue(Object? value) {
  if (value is num && value >= 0) {
    return Duration(seconds: value.ceil());
  }
  if (value is! String || value.trim().isEmpty) return null;

  final normalized = value.trim();
  final seconds = num.tryParse(normalized);
  if (seconds != null && seconds >= 0) {
    return Duration(seconds: seconds.ceil());
  }

  DateTime? retryAt = DateTime.tryParse(normalized)?.toUtc();
  if (retryAt == null) {
    try {
      retryAt = HttpDate.parse(normalized).toUtc();
    } on FormatException {
      return null;
    }
  }
  final remaining = retryAt.difference(DateTime.now().toUtc());
  return remaining.isNegative ? Duration.zero : remaining;
}

String? _requestLanguage(DioException e) {
  final value = e.requestOptions.headers['Accept-Language'];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}
