import 'dart:async';

import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/app_version/presentation/app_version_gate.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/app_version_policy_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Enjoy Lavash',
      packageName: 'com.aurumdev.enjoy_lavash_mobile',
      version: '1.2.3',
      buildNumber: '21',
      buildSignature: '',
    );
  });

  AppVersionPolicyModel policy({required bool force, bool update = true}) {
    return AppVersionPolicyModel.fromJson({
      'platform': 'android',
      'latestVersion': '1.3.0',
      'minSupportedVersion': force ? '1.3.0' : '1.0.0',
      'appUrl': 'https://play.google.com/store/apps/details?id=app',
      'updateAvailable': update,
      'forceUpdate': force,
    });
  }

  // The update icon pulses continuously, so pumpAndSettle would never return.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpGate(
    WidgetTester tester,
    AppVersionPolicyLoader loader,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppVersionGate(
          loadPolicy: loader,
          languageCode: 'en',
          child: const Scaffold(body: Text('menu')),
        ),
      ),
    );
  }

  testWidgets('shows the app immediately while the policy is loading', (
    tester,
  ) async {
    final pending = Completer<Result<AppVersionPolicyModel>>();
    await pumpGate(
      tester,
      ({required platform, currentVersion, language}) => pending.future,
    );
    await tester.pump();

    expect(find.text('menu'), findsOneWidget);
    expect(find.text('Update available'), findsNothing);
    expect(find.text('Update required'), findsNothing);
  });

  testWidgets('a failed policy request shows only the app', (tester) async {
    await pumpGate(
      tester,
      ({required platform, currentVersion, language}) async =>
          const Error<AppVersionPolicyModel>(NetworkFailure()),
    );
    await tester.pumpAndSettle();

    expect(find.text('menu'), findsOneWidget);
    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('a soft update can be dismissed and keeps the app', (
    tester,
  ) async {
    String? sentVersion;
    await pumpGate(tester, ({required platform, currentVersion, language}) {
      sentVersion = currentVersion;
      return Future.value(Success(policy(force: false)));
    });
    await settle(tester);

    expect(sentVersion, '1.2.3');
    expect(find.text('Update available'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await settle(tester);

    expect(find.text('Update available'), findsNothing);
    expect(find.text('menu'), findsOneWidget);
  });

  testWidgets('a forced update cannot be dismissed', (tester) async {
    await pumpGate(
      tester,
      ({required platform, currentVersion, language}) async =>
          Success(policy(force: true)),
    );
    await settle(tester);

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    final popScopes = tester
        .widgetList<PopScope<dynamic>>(
          find.byWidgetPredicate((widget) => widget is PopScope),
        )
        .toList();
    expect(popScopes, isNotEmpty);
    expect(popScopes.last.canPop, isFalse);
  });
}
