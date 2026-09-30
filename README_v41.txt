BMT GO v41 — RELEASE SUBMISSION HARDENED

Версия: 1.18.0+41
Application ID: com.bmtgo.app
compileSdk/targetSdk: 36

Что изменено:
- повышен versionCode до 41 и версия до 1.18.0;
- контакт поддержки petra03031983@gmail.com добавлен в страницу удаления аккаунта и политику конфиденциальности;
- добавлена отдельная проверка контактов и оставшихся release placeholders;
- сохранены требования Android API 36 и финальные release-проверки.

Перед публикацией:
1. Разместить docs/privacy_policy_ru.html на публичном HTTPS-адресе.
2. Разместить docs/account_deletion.html на публичном HTTPS-адресе.
3. На компьютере с Flutter и Android SDK 36 запустить tool/check_release_gate_v41.sh (или PowerShell-аналог, если он добавлен).
4. Собрать подписанный AAB и загрузить его в Google Play Console.

Важно: настоящий AAB и релизная подпись не создавались в этой среде, потому что Flutter/Android SDK здесь отсутствуют. Фиктивные ключи не добавлялись.
