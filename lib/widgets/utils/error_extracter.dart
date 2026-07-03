import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/error/mobile_error_messages.dart';

String extractErrorMessage(dynamic data) {
  return resolveApiErrorMessage(data: data, statusCode: 0, languageCode: null);
}

class Extracter {
  Extracter._();

  static String extractErrorMessage(DioException e) {
    return resolveApiErrorMessage(
      data: e.response?.data ?? e.message,
      statusCode: e.response?.statusCode ?? 0,
      languageCode: _requestLanguage(e),
    );
  }
}

String? _requestLanguage(DioException e) {
  final value = e.requestOptions.headers['Accept-Language'];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}
