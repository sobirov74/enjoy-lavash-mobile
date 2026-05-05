import 'package:dio/dio.dart';

String extractErrorMessage(dynamic data) {
  if (data is Map) {
    if (data['error'] != null) return data['error'];
    if (data['message'] != null) return data['message'];
    if (data['detail'] != null) return data['detail'];
  }

  if (data is String) return data;

  return "Something went wrong";
}

class Extracter {
  Extracter._();

  static String extractErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map) {
      return data['error'] ??
          data['message'] ??
          data['detail'] ??
          "Something went wrong";
    }

    if (data is String) return data;

    return e.message ?? "Network error";
  }
}
