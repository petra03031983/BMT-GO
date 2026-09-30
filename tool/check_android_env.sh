#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
command -v flutter >/dev/null || { echo 'FAIL: Flutter не найден'; exit 1; }
command -v java >/dev/null || { echo 'FAIL: Java не найдена'; exit 1; }
flutter --version | head -n2
java -version 2>&1 | head -n1
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -n "$SDK" && -f "$SDK/platforms/android-36/android.jar" ]]; then echo 'OK: Android SDK Platform 36'; else echo 'FAIL: Android SDK Platform 36 не найдена'; exit 1; fi
flutter doctor -v
