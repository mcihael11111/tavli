#!/usr/bin/env bash
# Lists connected Android devices (id + model). Exits 1 when none are usable.
set -euo pipefail
if command -v adb >/dev/null 2>&1; then
  ADB="$(command -v adb)"
else
  ADB=""
  for root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Library/Android/sdk"; do
    if [ -n "$root" ] && [ -x "$root/platform-tools/adb" ]; then
      ADB="$root/platform-tools/adb"
      break
    fi
  done
fi
if [ -z "$ADB" ]; then
  echo "adb not found. Put it on PATH or set ANDROID_HOME / ANDROID_SDK_ROOT." >&2
  exit 1
fi
devices=$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')
if [ -z "$devices" ]; then
  if "$ADB" devices | awk 'NR>1 && $2=="unauthorized" {f=1} END{exit !f}'; then
    echo "Device is unauthorized: authorize USB debugging on the phone." >&2
  else
    echo "No Android device connected. Enable USB debugging and plug in the phone." >&2
  fi
  exit 1
fi
for d in $devices; do
  model=$("$ADB" -s "$d" shell getprop ro.product.model | tr -d '\r')
  echo "$d $model"
done
