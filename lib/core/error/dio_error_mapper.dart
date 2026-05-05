import 'dart:io';

import 'package:dio/dio.dart';
import 'failures.dart';

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
      if (status == 401 || status == 403) {
        return const AuthFailure();
      }
      final serverMessage = _extractMessage(e.response?.data) ??
          'Server error ($status)';
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

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['message'] as String? ??
        data['error'] as String? ??
        data['detail'] as String?;
  }
  return null;
}
