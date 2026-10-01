#!/usr/bin/env bash
# Lists connected Android devices (id + model). Exits 1 when none are attached.
set -euo pipefail
ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
devices=$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')
if [ -z "$devices" ]; then
  echo "No Android device connected. Enable USB debugging and plug in the phone." >&2
  exit 1
fi
for d in $devices; do
  model=$("$ADB" -s "$d" shell getprop ro.product.model | tr -d '\r')
  echo "$d $model"
done
