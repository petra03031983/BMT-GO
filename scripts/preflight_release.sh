#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail=0
check(){ if [ "$2" = "1" ]; then echo "OK   $1"; else echo "FAIL $1"; fail=1; fi; }
check "pubspec.yaml exists" "$([ -f pubspec.yaml ] && echo 1 || echo 0)"
check "Android applicationId present" "$(grep -q "applicationId 'com.bmtgo.app'" android/app/build.gradle && echo 1 || echo 0)"
check "Release signing template present" "$([ -f android/key.properties.example ] && echo 1 || echo 0)"
check "MainActivity present" "$([ -f android/app/src/main/kotlin/com/bmtgo/app/MainActivity.kt ] && echo 1 || echo 0)"
check "Launcher icon present" "$([ -f android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png ] && echo 1 || echo 0)"
check "Privacy policy draft present" "$([ -f docs/privacy_policy_ru.html ] && echo 1 || echo 0)"
check "Account deletion SQL present" "$([ -f supabase/v33_account_deletion.sql ] && echo 1 || echo 0)"
if [ -f android/key.properties ]; then echo "WARN android/key.properties exists locally (do not commit it)"; else echo "OK   no local android/key.properties in source kit"; fi
if grep -R "SUPABASE_ANON_KEY\|GOOGLE_MAPS_API_KEY" -n lib >/dev/null; then echo "OK   runtime secrets are supplied via --dart-define"; else echo "WARN secret configuration not detected"; fi
if command -v flutter >/dev/null 2>&1; then
  echo "INFO Flutter found: running analyze"
  flutter pub get >/dev/null
  flutter analyze
else
  echo "WARN Flutter SDK not installed; build/analyze not executed here"
fi
if [ "$fail" -ne 0 ]; then exit 1; fi
echo "PRE-FLIGHT PASSED"
