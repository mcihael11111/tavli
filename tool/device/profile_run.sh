#!/usr/bin/env bash
# Runs integration_test/perf/<scenario>_test.dart in PROFILE mode on a device
# and writes build/perf/<reportKey>.timeline_summary.json.
# Usage: tool/device/profile_run.sh <scenario> [device-id]
set -euo pipefail
cd "$(dirname "$0")/../.."
scenario="${1:?usage: profile_run.sh <scenario> [device-id]}"
device="${2:-$(tool/device/check_device.sh | head -n1 | cut -d' ' -f1)}"
flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target="integration_test/perf/${scenario}_test.dart" \
  -d "$device"
echo "Summaries:"
ls -1 build/perf/*.timeline_summary.json
