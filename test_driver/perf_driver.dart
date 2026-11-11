import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Host side of `integration_test/perf_test.dart`: writes the frame timing
/// summaries (and, in debug runs, rebuild counts) to
/// `build/perf/perf_<PERF_TAG>.json`.
Future<void> main() {
  final tag = Platform.environment['PERF_TAG'] ?? 'run';
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      await writeResponseData(
        data,
        testOutputFilename: 'perf_$tag',
        destinationDirectory: 'build/perf',
      );
    },
  );
}
