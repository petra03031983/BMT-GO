#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok(){ echo "OK   $1"; }
warn(){ echo "WARN $1"; }
bad(){ echo "FAIL $1"; fail=1; }
command -v flutter >/dev/null 2>&1 && ok "Flutter found: $(flutter --version | head -n1)" || warn "Flutter SDK not installed / not on PATH"
command -v java >/dev/null 2>&1 && ok "Java found: $(java -version 2>&1 | head -n1)" || bad "Java not found"
command -v adb >/dev/null 2>&1 && ok "ADB found" || warn "ADB not found (optional for build)"
[[ -f "$ROOT/pubspec.yaml" ]] && ok "pubspec.yaml" || bad "pubspec.yaml missing"
grep -q "version: 1.15.0+37" "$ROOT/pubspec.yaml" && ok "Version 1.15.0+37" || bad "Wrong version"
grep -q "applicationId 'com.bmtgo.app'" "$ROOT/android/app/build.gradle" && ok "applicationId" || bad "Wrong applicationId"
grep -q "compileSdk 36" "$ROOT/android/app/build.gradle" && ok "compileSdk 36" || bad "compileSdk is not 36"
grep -q "targetSdk 36" "$ROOT/android/app/build.gradle" && ok "targetSdk 36" || bad "targetSdk is not 36"
grep -q "versionCode 37" "$ROOT/android/app/build.gradle" && ok "versionCode 37" || bad "versionCode is not 37"
[[ -f "$ROOT/docs/privacy_policy_ru.html" ]] && ok "Privacy policy" || bad "Privacy policy missing"
[[ -f "$ROOT/docs/account_deletion.html" ]] && ok "Account deletion page" || bad "Account deletion page missing"
[[ -f "$ROOT/docs/account_deletion.sql" ]] && ok "Account deletion SQL" || bad "Account deletion SQL missing"
if grep -RInE 'AIza[0-9A-Za-z_-]{20,}|SUPABASE_SERVICE_ROLE|BEGIN PRIVATE KEY|sk_live_|rk_live_' "$ROOT" --exclude='*.example' --exclude='*.md' >/dev/null 2>&1; then bad "Possible secret detected"; else ok "No obvious secrets detected"; fi
if command -v flutter >/dev/null 2>&1; then
  flutter --version >/dev/null
  flutter doctor -v >/tmp/bmtgo_flutter_doctor.txt 2>&1 || true
  grep -q 'Android toolchain' /tmp/bmtgo_flutter_doctor.txt && ok "Flutter Android toolchain detected" || warn "Flutter Android toolchain not confirmed"
fi
if [[ -n "${ANDROID_HOME:-}" || -n "${ANDROID_SDK_ROOT:-}" ]]; then ok "Android SDK environment variable set"; else warn "ANDROID_HOME/ANDROID_SDK_ROOT not set"; fi
if [[ -n "${SUPABASE_URL:-}" ]]; then ok "SUPABASE_URL supplied in environment"; else warn "SUPABASE_URL not supplied (required for real app build)"; fi
if [[ -n "${SUPABASE_ANON_KEY:-}" ]]; then ok "SUPABASE_ANON_KEY supplied in environment"; else warn "SUPABASE_ANON_KEY not supplied (required for real app build)"; fi
if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]]; then ok "GOOGLE_MAPS_API_KEY supplied in environment"; else warn "GOOGLE_MAPS_API_KEY not supplied (required for maps)"; fi
if [[ $fail -eq 0 ]]; then echo; echo "V37 PRE-RELEASE CHECK PASSED"; else echo; echo "V37 PRE-RELEASE CHECK FAILED"; exit 1; fi
