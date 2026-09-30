BMT GO v31 — Google Play release preparation

Версия: 1.9.0+31

Добавлено:
- Privacy Policy draft (docs/privacy_policy_ru.html)
- Google Play Data Safety draft (docs/google_play_data_safety_ru.md)
- Release checklist (docs/release_checklist_ru.md)
- versionCode 31 / versionName 1.9.0
- подготовка к release signing

Важно: перед публикацией нужно заменить контакт в Privacy Policy, разместить политику на HTTPS, настроить release keystore, production backend/Firebase/Maps/payment secrets и заполнить Data Safety по фактической конфигурации.

Сборка AAB на компьютере с Flutter:
flutter pub get
flutter build appbundle --release
