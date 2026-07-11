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

  test('maps migration statuses to explicit failure types', () {
    Failure mapStatus(int statusCode, {Headers? headers}) {
      final options = RequestOptions(
        path: '/auth/request-otp',
        headers: {'Accept-Language': 'en'},
      );
      return mapDioError(
        DioException.badResponse(
          statusCode: statusCode,
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: statusCode,
            headers: headers,
          ),
        ),
      );
    }

    expect(mapStatus(409), isA<ConflictFailure>());
    expect(mapStatus(413), isA<PayloadTooLargeFailure>());
    expect(mapStatus(503), isA<ServiceUnavailableFailure>());

    final rateLimit = mapStatus(
      429,
      headers: Headers.fromMap({
        'retry-after': ['45'],
      }),
    );
    expect(rateLimit, isA<RateLimitFailure>());
    expect(
      (rateLimit as RateLimitFailure).retryAfter,
      const Duration(seconds: 45),
    );
  });

  test('uses localized defaults for migration status codes', () {
    expect(
      resolveApiErrorMessage(data: null, statusCode: 429, languageCode: 'ru'),
      'Слишком много запросов. Попробуйте позже.',
    );
    expect(
      resolveApiErrorMessage(data: null, statusCode: 503, languageCode: 'uz'),
      'Xizmat vaqtincha ishlamayapti. Qayta urinib ko‘ring.',
    );
  });
}
