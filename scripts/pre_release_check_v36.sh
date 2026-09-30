#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok(){ echo "OK   $1"; }
bad(){ echo "FAIL $1"; fail=1; }
[[ -f "$ROOT/pubspec.yaml" ]] && ok "pubspec.yaml" || bad "pubspec.yaml missing"
grep -q "version: 1.14.0+36" "$ROOT/pubspec.yaml" && ok "version 1.14.0+36" || bad "pubspec version mismatch"
grep -q "applicationId 'com.bmtgo.app'" "$ROOT/android/app/build.gradle" && ok "applicationId com.bmtgo.app" || bad "applicationId missing"
grep -q "compileSdk 36" "$ROOT/android/app/build.gradle" && ok "compileSdk 36" || bad "compileSdk is not 36"
grep -q "targetSdk 36" "$ROOT/android/app/build.gradle" && ok "targetSdk 36" || bad "targetSdk is not 36"
grep -q "versionCode 36" "$ROOT/android/app/build.gradle" && ok "versionCode 36" || bad "versionCode mismatch"
[[ -f "$ROOT/docs/privacy_policy_ru.html" ]] && ok "privacy policy" || bad "privacy policy missing"
[[ -f "$ROOT/docs/account_deletion.html" ]] && ok "account deletion page" || bad "account deletion page missing"
[[ -f "$ROOT/supabase/v33_account_deletion.sql" ]] && ok "account deletion SQL" || bad "account deletion SQL missing"
if grep -RniE 'sk_live_|sk_test_|CHANGE_ME|YOUR_[A-Z0-9_]+|REPLACE_ME' "$ROOT/lib" "$ROOT/android" --exclude='key.properties.example' >/tmp/bmt_v36_scan 2>/dev/null; then
  cat /tmp/bmt_v36_scan; bad "placeholder/secret detected"
else ok "no obvious secrets/placeholders"; fi
if command -v flutter >/dev/null 2>&1; then
  ok "Flutter SDK found"
else
  echo "WARN Flutter SDK not installed here; AAB build not executed"
fi
if [[ $fail -ne 0 ]]; then exit 1; fi
echo "V36 PRE-RELEASE CHECK PASSED"
