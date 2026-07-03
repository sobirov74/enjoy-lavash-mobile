import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/error/dio_error_mapper.dart';
import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/mobile_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('translates known error code using requested language', () {
    final message = resolveApiErrorMessage(
      data: {
        'errorCode': 'PHONE_REQUIRED',
        'message': 'Wrong backend language',
      },
      statusCode: 400,
      languageCode: 'uz',
    );

    expect(message, 'Telefon raqami talab qilinadi');
  });

  test('falls back to backend message for unknown error code', () {
    final message = resolveApiErrorMessage(
      data: {'errorCode': 'NEW_BACKEND_CODE', 'message': 'Backend fallback'},
      statusCode: 400,
      languageCode: 'ru',
    );

    expect(message, 'Backend fallback');
  });

  test('maps Dio bad response with local error code message', () {
    final failure = mapDioError(
      DioException.badResponse(
        statusCode: 400,
        requestOptions: RequestOptions(
          path: '/auth/request-otp',
          headers: {'Accept-Language': 'ru'},
        ),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/request-otp'),
          statusCode: 400,
          data: {
            'errorCode': 'PHONE_REQUIRED',
            'message': 'Telefon raqami talab qilinadi',
          },
        ),
      ),
    );

    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Номер телефона обязателен');
  });
}
