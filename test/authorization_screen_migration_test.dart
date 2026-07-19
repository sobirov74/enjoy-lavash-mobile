import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/app/locale_controller.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/authorization_screen.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'OTP success uses server expiry and never shows a supplied code',
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
      await _pumpUntilFound(tester, find.text('Enter SMS code'));

      expect(find.text('Enter SMS code'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Code expires in')), findsOneWidget);
      expect(find.textContaining('Demo'), findsNothing);
    },
  );

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
    await _pumpUntilFound(tester, find.textContaining('Try again in'));

    expect(find.textContaining('Try again in'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('Enter SMS code'), findsNothing);
  });

  testWidgets('OTP 503 stays on phone entry and allows manual retry', (
    tester,
  ) async {
    await _pumpAuthorization(
      tester,
      _Adapter((_) async {
        return _jsonResponse(const <String, Object?>{}, statusCode: 503);
      }),
    );

    await tester.tap(find.text('Send code'));
    await _pumpUntilFound(
      tester,
      find.text('The service is temporarily unavailable. Please try again.'),
    );

    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('Enter SMS code'), findsNothing);
    expect(
      find.text('The service is temporarily unavailable. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('new client sees the birth date step after the name step', (
    tester,
  ) async {
    await _pumpAuthorizationLauncher(
      tester,
      _authAdapter(clientCreated: true, birthDate: null),
    );

    await _completeOtp(tester);
    await _pumpUntilFound(tester, find.text('Name (optional)'));

    expect(find.text('Your special day 🎂'), findsNothing);
    await tester.tap(find.text('Skip'));
    await _pumpUntilFound(tester, find.text('Your special day 🎂'));

    expect(
      find.byKey(const ValueKey<String>('birth-date-field')),
      findsOneWidget,
    );
  });

  testWidgets('returning client without a birth date sees the date input', (
    tester,
  ) async {
    await _pumpAuthorizationLauncher(
      tester,
      _authAdapter(clientCreated: false, birthDate: null),
    );

    await _completeOtp(tester);
    await _pumpUntilFound(tester, find.text('Your special day 🎂'));

    expect(find.text('Name (optional)'), findsNothing);
    expect(find.text('Date of birth'), findsOneWidget);
  });

  testWidgets('returning client with a birth date completes authorization', (
    tester,
  ) async {
    await _pumpAuthorizationLauncher(
      tester,
      _authAdapter(clientCreated: false, birthDate: '1995-04-07'),
    );

    await _completeOtp(tester);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey<String>('authorization-launcher')),
    );

    expect(find.text('Your special day 🎂'), findsNothing);
  });

  testWidgets('birth date save sends a date-only profile update', (
    tester,
  ) async {
    Map<String, Object?>? profileUpdate;
    final now = DateTime.now();
    final expectedDate = '${now.year - 18}-01-01';
    await _pumpAuthorizationLauncher(
      tester,
      _authAdapter(
        clientCreated: false,
        birthDate: null,
        onProfileUpdate: (data) => profileUpdate = data,
      ),
    );

    await _completeOtp(tester);
    await _pumpUntilFound(tester, find.text('Your special day 🎂'));
    await tester.tap(find.byKey(const ValueKey<String>('birth-date-field')));
    await _pumpUntilFound(tester, find.text('OK'));
    final datePicker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(datePicker.firstDate, DateTime(1900));
    expect(datePicker.lastDate, DateTime(now.year, now.month, now.day));
    await tester.tap(find.text('OK'));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey<String>('birth-date-save-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('birth-date-save-button')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey<String>('authorization-launcher')),
    );

    expect(profileUpdate, {'birthDate': expectedDate});
  });
}

Future<void> _completeOtp(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>('authorization-launcher')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Send code'));
  await _pumpUntilFound(tester, find.byType(Pinput));
  await tester.enterText(find.byType(Pinput), '1111');
}

HttpClientAdapter _authAdapter({
  required bool clientCreated,
  required String? birthDate,
  void Function(Map<String, Object?> data)? onProfileUpdate,
}) {
  return _Adapter((options) async {
    switch (options.uri.path) {
      case ApiEndpoints.requestOtp:
        return _jsonResponse({
          'phoneNumber': '+998',
          'codeExpiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 2))
              .toIso8601String(),
        });
      case ApiEndpoints.verifyOtp:
        return _jsonResponse({
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
          'refresh_token_expires_at': DateTime.now()
              .toUtc()
              .add(const Duration(days: 30))
              .toIso8601String(),
          'token_type': 'Bearer',
          'client_created': clientCreated,
          'client': _clientJson(birthDate: birthDate),
        });
      case ApiEndpoints.clientMe:
        final data = Map<String, Object?>.from(options.data as Map);
        onProfileUpdate?.call(data);
        return _jsonResponse(
          _clientJson(birthDate: data['birthDate'] as String?),
        );
      case ApiEndpoints.clientNotifications:
        return _jsonResponse({
          'items': const <Object?>[],
          'unreadCount': 0,
          'total': 0,
          'limit': 50,
          'offset': 0,
        });
      default:
        throw StateError(
          'Unexpected request: ${options.method} ${options.path}',
        );
    }
  });
}

Map<String, Object?> _clientJson({required String? birthDate}) {
  return <String, Object?>{
    'id': 'client-id',
    'fullName': 'Ali Valiyev',
    'phoneNumber': '+998901234567',
    'language': 'en',
    'bonusBalance': 0,
    'birthDate': birthDate,
    'marketingConsent': false,
    'isBlocked': false,
  };
}

Future<void> _pumpAuthorizationLauncher(
  WidgetTester tester,
  HttpClientAdapter adapter,
) async {
  final apiClient = ApiClient(
    baseUrl: 'https://example.test',
    httpClientAdapter: adapter,
  );
  apiClient.setLanguage('en');
  final controller = MobileBackendController(
    MobileBackendRepositoryImpl(apiClient),
    MobilePushNotificationService(apiClient),
  );
  final localeController = LocaleController();
  await localeController.setLocale(const Locale('en'));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MobileBackendController>.value(
          value: controller,
        ),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
      ],
      child: MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey<String>('authorization-launcher'),
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => const AuthorizationScreen(),
                  ),
                ),
                child: const Text('Open authorization'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
}) async {
  for (var pump = 0; pump < maxPumps && finder.evaluate().isEmpty; pump++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsWidgets);
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _pumpAuthorization(
  WidgetTester tester,
  HttpClientAdapter adapter,
) async {
  final apiClient = ApiClient(
    baseUrl: 'https://example.test',
    httpClientAdapter: adapter,
  );
  apiClient.setLanguage('en');
  final controller = MobileBackendController(
    MobileBackendRepositoryImpl(apiClient),
    MobilePushNotificationService(apiClient),
  );
  final localeController = LocaleController();
  await localeController.setLocale(const Locale('en'));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MobileBackendController>.value(
          value: controller,
        ),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
      ],
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
