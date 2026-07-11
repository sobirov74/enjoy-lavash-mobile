import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('OTP success uses server expiry and never shows a supplied code',
      (tester) async {
    await _pumpAuthorization(
      tester,
      _Adapter((options) async {
        expect(options.uri.path, ApiEndpoints.requestOtp);
        return _jsonResponse({
          'phoneNumber': '+998',
          'codeExpiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 2))
              .toIso8601String(),
        });
      }),
    );

    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Enter SMS code'), findsOneWidget);
    expect(find.textContaining('Code expires in'), findsOneWidget);
    expect(find.textContaining('Demo'), findsNothing);
  });

  testWidgets('OTP 429 applies the Retry-After cooldown', (tester) async {
    await _pumpAuthorization(
      tester,
      _Adapter((_) async {
        return _jsonResponse(
          const <String, Object?>{},
          statusCode: 429,
          headers: {
            'retry-after': ['30'],
          },
        );
      }),
    );

    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Try again in'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(find.text('Enter SMS code'), findsNothing);
  });

  testWidgets('OTP 503 stays on phone entry and allows manual retry',
      (tester) async {
    await _pumpAuthorization(
      tester,
      _Adapter((_) async {
        return _jsonResponse(const <String, Object?>{}, statusCode: 503);
      }),
    );

    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('Enter SMS code'), findsNothing);
    expect(
      find.text(
        'The service is temporarily unavailable. Please try again.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });
}

Future<void> _pumpAuthorization(
  WidgetTester tester,
  HttpClientAdapter adapter,
) async {
  final apiClient = ApiClient(
    baseUrl: 'https://example.test',
    httpClientAdapter: adapter,
  );
  final controller = MobileBackendController(
    MobileBackendRepositoryImpl(apiClient),
    MobilePushNotificationService(apiClient),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<MobileBackendController>.value(
      value: controller,
      child: MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: const AuthorizationScreen(),
      ),
    ),
  );
  await tester.pump();
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  Map<String, Object?> data, {
  int statusCode = 200,
  Map<String, List<String>> headers = const <String, List<String>>{},
}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}
