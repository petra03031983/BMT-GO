#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail=0
check(){ if eval "$2" >/dev/null 2>&1; then echo "OK  $1"; else echo "FAIL $1"; fail=1; fi; }
check 'pubspec version 1.19.0+42' "grep -q '^version: 1.19.0+42' pubspec.yaml"
check 'applicationId com.bmtgo.app' "grep -Eq \"applicationId[[:space:]]+['\\\"]com\\.bmtgo\\.app['\\\"]\" android/app/build.gradle"
check 'compileSdk 36' "grep -q 'compileSdk 36' android/app/build.gradle"
check 'targetSdk 36' "grep -q 'targetSdk 36' android/app/build.gradle"
check 'versionCode 42' "grep -q 'versionCode 42' android/app/build.gradle"
check 'privacy policy exists' "test -s docs/privacy_policy_ru.html"
check 'privacy support email' "grep -q 'petra03031983@gmail.com' docs/privacy_policy_ru.html"
check 'account deletion page exists' "test -s docs/account_deletion.html"
check 'account deletion support email' "grep -q 'petra03031983@gmail.com' docs/account_deletion.html"
if grep -RniE --exclude='*.example' --exclude='*.zip' 'УКАЖИТЕ_РАБОЧИЙ_EMAIL|Добавьте здесь официальный e-mail|example\.com|YOUR_[A-Z_]+|REPLACE_ME|CHANGE_ME' docs android/app lib pubspec.yaml >/tmp/bmtgo_gate_v41_hits 2>/dev/null; then
  echo 'FAIL placeholder text found:'; cat /tmp/bmtgo_gate_v41_hits; fail=1
else echo 'OK  no release placeholders'; fi
if command -v flutter >/dev/null 2>&1; then echo 'OK  Flutter available'; else echo 'WARN Flutter not installed in this environment'; fi
if [ -n "${ANDROID_SDK_ROOT:-}" ] && [ -f "$ANDROID_SDK_ROOT/platforms/android-36/android.jar" ]; then echo 'OK  Android SDK Platform 36'; else echo 'WARN Android SDK Platform 36 not verified here'; fi
if [ "$fail" -eq 0 ]; then echo 'V41 RELEASE GATE PASSED'; else echo 'V41 RELEASE GATE FAILED'; exit 1; fi
