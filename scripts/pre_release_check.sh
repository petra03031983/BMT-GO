#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
check(){ if [[ -e "$ROOT/$1" ]]; then echo "OK  $1"; else echo "FAIL $1"; fail=1; fi; }
check pubspec.yaml
check android/app/build.gradle
check android/app/src/main/AndroidManifest.xml
check android/app/src/main/kotlin/com/bmtgo/app/MainActivity.kt
check docs/privacy_policy_ru.html
check docs/account_deletion.html
check docs/google_play_data_safety_ru.md
check docs/release_checklist_v35_ru.md
if [[ -e "$ROOT/android/key.properties" ]]; then echo "WARN android/key.properties exists locally (never commit it)"; fi
if grep -RniE 'example\.com|YOUR_|REPLACE_ME|CHANGE_ME|sk_live_|sk_test_|pk_live_|pk_test_' lib android --exclude='key.properties.example' 2>/dev/null | head -20; then
  echo "FAIL possible placeholder/secret detected"; fail=1
else
  echo "OK  no obvious placeholders/secrets"
fi
if grep -q 'version: 1.13.0+35' pubspec.yaml && grep -q "versionCode 35" android/app/build.gradle && grep -q "versionName '1.13.0'" android/app/build.gradle; then echo "OK  version 1.13.0+35"; else echo "FAIL version mismatch"; fail=1; fi
if [[ $fail -ne 0 ]]; then exit 1; fi
echo "PRE-RELEASE CHECK PASSED"
