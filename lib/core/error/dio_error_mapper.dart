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
      if (status == 401) {
        return AuthFailure(serverMessage);
      }
      return ServerFailure(status, serverMessage);

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

String? _requestLanguage(DioException e) {
  final value = e.requestOptions.headers['Accept-Language'];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}
