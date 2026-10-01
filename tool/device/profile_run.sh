#!/usr/bin/env bash
# Runs integration_test/perf/<scenario>_test.dart in PROFILE mode on a device
# and writes build/perf/<reportKey>.timeline_summary.json.
# Usage: tool/device/profile_run.sh <scenario> [device-id]
set -euo pipefail
cd "$(dirname "$0")/../.."
scenario="${1:?usage: profile_run.sh <scenario> [device-id]}"
if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH." >&2
  exit 1
fi
devices_out=$(tool/device/check_device.sh)
device="${2:-$(printf '%s\n' "$devices_out" | awk 'NR==1{print $1}')}"
echo "Using device: $(printf '%s\n' "$devices_out" | awk -v d="$device" '$1==d{print}')"
rm -rf build/perf
# --no-dds: traceAction needs a direct VM-service connection (DDS blocks it).
# --endless-trace-buffer: keep the start of a ~30 s trace.
flutter drive --profile --no-dds --endless-trace-buffer \
  --driver=test_driver/perf_driver.dart \
  --target="integration_test/perf/${scenario}_test.dart" \
  -d "$device"
echo "Summaries:"
ls -1 build/perf/*.timeline_summary.json
