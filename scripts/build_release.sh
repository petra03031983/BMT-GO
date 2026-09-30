#!/usr/bin/env bash
set -euo pipefail
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Install Flutter and run this script again." >&2
  exit 1
fi
if [ ! -f android/key.properties ]; then
  echo "android/key.properties not found. Run ./scripts/create_upload_keystore.sh first." >&2
  exit 1
fi
flutter clean
flutter pub get
flutter build appbundle --release
