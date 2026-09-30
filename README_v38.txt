BMT GO v38 — RELEASE HARDENING

Версия: 1.16.0+38
Android target/compile SDK: 36

Что изменено:
- усилена проверка Android SDK Platform 36;
- build_release.ps1 и build_release.sh сначала проверяют окружение;
- после сборки скрипты проверяют наличие app-release.aab;
- обновлен pre_release_check_v38.sh;
- секреты не записываются в исходники: ключи передаются через --dart-define.

Windows:
  cd путь\к\bmtgo
  powershell -ExecutionPolicy Bypass -File .\tool\build_release.ps1

Linux/macOS:
  export SUPABASE_URL='...'
  export SUPABASE_ANON_KEY='...'
  export GOOGLE_MAPS_API_KEY='...'
  ./tool/build_release.sh

Важно: для Google Play с 31 августа 2026 новые приложения и обновления должны target Android 16 / API 36 или выше.
