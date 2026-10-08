import 'dart:convert';
import 'dart:math';

import 'package:enjoy_lavash_mobile/core/error/failures.dart';

/// Hands out the `Idempotency-Key` for order creation.
///
/// The same payload keeps the same key until the server gives a definite
/// answer. After a network error, timeout or 5xx the order may already exist,
/// so submitting the identical order again (even after the customer closed the
/// error dialog) reuses the key and the server returns the original order
/// instead of creating a duplicate. Any change to the payload gets a new key,
/// because the server rejects a reused key with a different body.
class OrderSubmissionKeys {
  OrderSubmissionKeys({String Function()? generateKey})
    : _generateKey = generateKey ?? newIdempotencyKey;

  final String Function() _generateKey;
  String? _fingerprint;
  String? _key;

  /// Key for [payload]; stable while the previous attempt is unresolved.
  String keyFor(Map<String, Object?> payload) {
    final fingerprint = jsonEncode(payload);
    final current = _key;
    if (current != null && fingerprint == _fingerprint) return current;
    _fingerprint = fingerprint;
    return _key = _generateKey();
  }

  /// Records the outcome of an attempt. The key is kept only when the server
  /// may have created the order without the client learning about it.
  void resolve({required bool succeeded, Failure? failure}) {
    if (!succeeded && failure != null && isOutcomeUnknown(failure)) return;
    _fingerprint = null;
    _key = null;
  }

  /// Whether a failed create-order call may still have created the order.
  static bool isOutcomeUnknown(Failure failure) {
    return failure is NetworkFailure ||
        failure is TimeoutFailure ||
        (failure is ServerFailure && failure.statusCode >= 500);
  }
}

/// Random RFC 4122 version-4 UUID.
String newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}
