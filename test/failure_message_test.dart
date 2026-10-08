import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations_ru.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/failure_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t = LRu();

  test('server copy (already localized by the mapper) passes through', () {
    const failure = ServerFailure(422, 'Неверный или просроченный OTP код');
    expect(failureMessage(t, failure), 'Неверный или просроченный OTP код');
    expect(failureDetail(t, failure), 'Неверный или просроченный OTP код');
  });

  test('connectivity failures use the app copy, never English defaults', () {
    expect(failureMessage(t, const NetworkFailure()), t.errorConnectionProblem);
    expect(failureMessage(t, const TimeoutFailure()), t.errorSlowNetwork);
    // Under a heading that already says "connection problem".
    expect(failureDetail(t, const NetworkFailure()), t.errorGenericBody);
  });

  test('raw exception text never reaches the customer', () {
    for (final failure in <Failure>[
      UnknownFailure(
        "type 'Null' is not a subtype of type 'String' in type cast",
      ),
      const UnknownFailure('FormatException: Unexpected character'),
      const ServerFailure(500, 'DioException [bad response]: status 500'),
      const ServerFailure(500),
      const AuthFailure(),
    ]) {
      expect(
        failureMessage(t, failure, fallback: t.orderCreateFailed),
        t.orderCreateFailed,
        reason: failure.toString(),
      );
    }
    expect(failureMessage(t, const UnknownFailure()), t.errorGenericTitle);
  });
}
