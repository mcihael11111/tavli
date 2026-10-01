#!/usr/bin/env bash
# The one definition of "green". CI runs exactly this; so should you before
# every commit that claims to pass.
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "== pub get"
flutter pub get

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
  (cd "$pkg" && dart test --reporter=compact)
done

echo "== app tests"
flutter test --reporter=compact

echo "ALL GREEN"
