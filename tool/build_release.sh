#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
"$ROOT/tool/check_android_env.sh"
: "${SUPABASE_URL:?Укажите SUPABASE_URL}"
: "${SUPABASE_ANON_KEY:?Укажите SUPABASE_ANON_KEY}"
: "${GOOGLE_MAPS_API_KEY:?Укажите GOOGLE_MAPS_API_KEY}"
flutter clean
flutter pub get
flutter build appbundle --release \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
  --dart-define="GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
ARTIFACT="$ROOT/build/app/outputs/bundle/release/app-release.aab"
test -f "$ARTIFACT" || { echo "FAIL: AAB не найден: $ARTIFACT"; exit 1; }
echo "ГОТОВО: $ARTIFACT"
