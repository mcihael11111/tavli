import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Host-side driver for `flutter drive --profile`. Every `traceAction`
/// reportKey from the device becomes `build/perf/<key>.timeline_summary.json`
/// (frame build/raster percentiles, missed-frame counts) plus the raw timeline.
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic> ||
            !value.containsKey('traceEvents')) {
          continue;
        }
        final timeline = driver.Timeline.fromJson(value);
        final summary = driver.TimelineSummary.summarize(timeline);
        await summary.writeTimelineToFile(
          entry.key,
          destinationDirectory: 'build/perf',
          pretty: true,
          includeSummary: true,
        );
      }
    },
  );
}
