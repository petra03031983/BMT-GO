#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok(){ echo "OK   $1"; }
bad(){ echo "FAIL $1"; fail=1; }
warn(){ echo "WARN $1"; }
[[ -f "$ROOT/pubspec.yaml" ]] && ok pubspec || bad 'pubspec missing'
grep -q 'version: 1.16.0+38' "$ROOT/pubspec.yaml" && ok 'version 1.16.0+38' || bad 'wrong version'
grep -q "applicationId 'com.bmtgo.app'" "$ROOT/android/app/build.gradle" && ok applicationId || bad 'wrong applicationId'
grep -q 'compileSdk 36' "$ROOT/android/app/build.gradle" && ok 'compileSdk 36' || bad 'compileSdk'
grep -q 'targetSdk 36' "$ROOT/android/app/build.gradle" && ok 'targetSdk 36' || bad 'targetSdk'
grep -q 'versionCode 38' "$ROOT/android/app/build.gradle" && ok 'versionCode 38' || bad 'versionCode'
[[ -f "$ROOT/docs/privacy_policy_ru.html" ]] && ok 'privacy policy' || bad 'privacy policy missing'
[[ -f "$ROOT/docs/account_deletion.html" ]] && ok 'account deletion page' || bad 'account deletion page missing'
[[ -f "$ROOT/docs/account_deletion.sql" ]] && ok 'account deletion SQL' || bad 'account deletion SQL missing'
if grep -RInE 'AIza[0-9A-Za-z_-]{20,}|SUPABASE_SERVICE_ROLE|BEGIN PRIVATE KEY|sk_live_|rk_live_' "$ROOT" --exclude='*.example' --exclude='*.md' >/dev/null 2>&1; then bad 'possible secret detected'; else ok 'no obvious secrets'; fi
if [[ -n "${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}" ]]; then ok 'Android SDK variable set'; else warn 'Android SDK variable not set'; fi
if command -v flutter >/dev/null 2>&1; then ok "Flutter: $(flutter --version | head -n1)"; else warn 'Flutter not installed in this environment'; fi
if [[ $fail -eq 0 ]]; then echo; echo 'V38 PRE-RELEASE CHECK PASSED'; else exit 1; fi
