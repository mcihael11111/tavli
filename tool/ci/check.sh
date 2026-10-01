#!/usr/bin/env bash
# The one definition of "green". CI runs exactly this; so should you before
# every commit that claims to pass.
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "== pub get"
flutter pub get --enforce-lockfile

echo "== analyze (whole workspace)"
dart analyze --fatal-infos

echo "== format (new code only — legacy code is deleted, not reformatted)"
fmt_paths=()
for p in packages lib/gameplay server test/architecture test/bench \
         integration_test/perf test_driver; do
  [ -e "$p" ] && fmt_paths+=("$p")
done
dart format --output=none --set-exit-if-changed "${fmt_paths[@]}"

echo "== package tests"
for pkg in packages/*/; do
  (cd "$pkg" && dart test --reporter=compact --exclude-tags bench)
done

# Budgeted benchmarks run alone (one suite at a time) so that other suites
# do not skew their timings. TAVLI_BENCH_SCALE (default 1) relaxes every
# budget on slow runners.
echo "== package benchmarks (tag bench, TAVLI_BENCH_SCALE=${TAVLI_BENCH_SCALE:-1})"
for pkg in packages/*/; do
  if grep -rqs "@Tags(\['bench'\])" "$pkg"test "$pkg"benchmark; then
    (cd "$pkg" && dart test --reporter=compact --tags bench --concurrency=1)
  fi
done

echo "== app tests"
flutter test --reporter=compact

echo "ALL GREEN"
