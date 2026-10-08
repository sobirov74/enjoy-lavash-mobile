import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';

/// English defaults baked into the [Failure] constructors. They are never
/// shown to customers, who may be reading Uzbek or Russian.
const Set<String> _untranslatedDefaults = <String>{
  'No internet connection',
  'Server error',
  'Request conflict',
  'Request is too large',
  'Too many requests',
  'Service temporarily unavailable',
  'Cache error',
  'Request timed out',
  'Authentication failed',
  'Something went wrong',
  'Unknown error',
  'Request cancelled',
  'Certificate error',
};

/// Fragments that only appear in Dart/Dio exception text, never in copy.
final RegExp _internalErrorText = RegExp(
  r"Exception|Error:|type '|Null check|is not a subtype|Instance of|"
  r'StackTrace|RangeError|NoSuchMethod|\bdio\b',
  caseSensitive: false,
);

/// A localized sentence for [failure], suitable on its own (snackbar, inline
/// error). Server messages, which the error mapper already localizes, pass
/// through; connectivity problems get the app's own copy; anything else falls
/// back to [fallback] or a generic message. Raw exception text never leaks.
String failureMessage(L t, Failure failure, {String? fallback}) {
  return switch (failure) {
    NetworkFailure() => t.errorConnectionProblem,
    TimeoutFailure() => t.errorSlowNetwork,
    _ => _customerSafeMessage(failure) ?? fallback ?? t.errorGenericTitle,
  };
}

/// The detail line under a heading that already names the failure type (for
/// example "Connection problem"), so connectivity failures do not repeat it.
String failureDetail(L t, Failure failure, {String? fallback}) {
  return _customerSafeMessage(failure) ?? fallback ?? t.errorGenericBody;
}

String? _customerSafeMessage(Failure failure) {
  if (failure is! ServerFailure && failure is! AuthFailure) return null;
  final message = failure.message.trim();
  if (message.isEmpty) return null;
  if (_untranslatedDefaults.contains(message)) return null;
  if (_internalErrorText.hasMatch(message)) return null;
  return message;
}
