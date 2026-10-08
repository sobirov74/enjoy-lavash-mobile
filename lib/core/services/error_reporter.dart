import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Production crash and error reporting through Sentry.
///
/// Enabled only when the build passes `--dart-define=SENTRY_DSN=…` (and
/// optionally `APP_ENV=staging`). Without a DSN nothing is initialised and
/// nothing leaves the device, so local runs and tests are unaffected.
///
/// Sentry chains onto the app's own `FlutterError.onError` and
/// `PlatformDispatcher.onError`, so those handlers should only log locally;
/// [report] is for errors no Sentry integration sees (zone errors, failures
/// the app catches and survives).
class ErrorReporter {
  ErrorReporter._();

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');
  static const String _environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static bool _initialised = false;

  static bool get isEnabled => _initialised;

  static Future<void> init() async {
    if (_dsn.isEmpty || _initialised) return;
    try {
      await SentryFlutter.init((options) {
        options
          ..dsn = _dsn
          ..environment = _environment
          // No personal data: no IPs, no user, no request bodies, no
          // screenshots (view hierarchy is off by default), and no print
          // breadcrumbs (debug logs may contain
          // checkout data).
          ..sendDefaultPii = false
          ..enablePrintBreadcrumbs = false
          ..attachScreenshot = false
          ..enableAutoPerformanceTracing = false
          ..tracesSampleRate = null;
      });
      _initialised = true;
    } catch (error) {
      debugPrint('Error reporting unavailable: ${error.runtimeType}');
    }
  }

  static void report(Object error, StackTrace stackTrace, {String? context}) {
    debugPrint(
      'Unhandled app error${context == null ? '' : ' ($context)'}: '
      '${error.runtimeType}',
    );
    debugPrintStack(stackTrace: stackTrace, maxFrames: 20);
    if (!_initialised) return;
    unawaited(
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: context == null
            ? null
            : (scope) => scope.setTag('context', context),
      ),
    );
  }
}
