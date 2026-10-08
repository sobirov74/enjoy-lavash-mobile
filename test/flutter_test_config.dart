import 'dart:async';

import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/cached_image_provider.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Widget tests have neither a cache directory nor a network: the plain
  // NetworkImage fails fast (the test binding answers HTTP 400) and widgets
  // render their fallbacks, exactly as they did before the disk cache.
  networkImageProvider = NetworkImage.new;
  // TokenStorage keeps the access token in memory; tests reset the mocked
  // keystore per test, so the cache must not carry a token across tests.
  setUp(TokenStorage.resetStorage);
  await testMain();
}
