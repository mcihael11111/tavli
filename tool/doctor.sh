#!/usr/bin/env bash
# Checks the machine is ready for the gameplay rewrite (spec §7 prerequisites).
# Prints a checklist; exits non-zero if any REQUIRED item fails.
# macOS-only (developer machine): uses `df -g` and /usr/libexec/java_home.
set -uo pipefail
fail=0
ok()   { printf '  \xE2\x9C\x93 %s\n' "$1"; }
bad()  { printf '  \xE2\x9C\x97 %s\n' "$1"; [ "${2:-req}" = req ] && fail=1; }

echo "Required"
free_gb=$(df -g / | awk 'NR==2 {print $4}')
if [ "${free_gb:-0}" -ge 15 ]; then ok "disk free ${free_gb} GB (>= 15)"; else bad "disk free ${free_gb} GB — need >= 15 GB for Android builds"; fi
if command -v flutter >/dev/null; then
  v=$(flutter --version 2>/dev/null | head -1)
  case "$v" in *"3.41."*) ok "$v";; *) bad "Flutter 3.41.x required, found: $v";; esac
else bad "flutter not on PATH"; fi
# Same lookup order as tool/device/check_device.sh.
ADB=$(command -v adb || true)
for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Library/Android/sdk"; do
  [ -z "$ADB" ] && [ -n "$sdk" ] && [ -x "$sdk/platform-tools/adb" ] && ADB="$sdk/platform-tools/adb"
done
if [ -n "$ADB" ]; then ok "adb at $ADB"; else bad "adb not found"; fi

echo "Needed for device verification"
if devices_out=$("$(dirname "$0")/device/check_device.sh" 2>/dev/null); then
  ok "device: $(printf '%s\n' "$devices_out" | awk 'NR==1')"
else bad "no Android device connected (USB debugging)" opt; fi

echo "Needed from SP4 (online)"
if command -v firebase >/dev/null; then ok "firebase CLI $(firebase --version)"; else bad "firebase CLI missing — npm i -g firebase-tools" opt; fi
if command -v gcloud >/dev/null; then ok "gcloud $(gcloud --version 2>/dev/null | head -1)"; else bad "gcloud missing — https://cloud.google.com/sdk/docs/install" opt; fi
if /usr/libexec/java_home >/dev/null 2>&1; then ok "java $(/usr/libexec/java_home)"; else bad "JDK missing (Firebase emulators need Java 11+)" opt; fi

echo "Optional"
if command -v xcodebuild >/dev/null && xcodebuild -version >/dev/null 2>&1; then ok "Xcode"; else bad "Xcode not installed — iOS verification deferred" opt; fi

exit $fail
