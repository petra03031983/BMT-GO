# BMT GO v38 — сборка и загрузка в Google Play

Версия: **1.16.0 (versionCode 38)**. Целевой Android: **API 36**.

## 1. На компьютере
Установить Flutter, Android Studio и Android SDK Platform 36. Проверьте:
- `flutter --version`
- `flutter doctor -v`
- `sdkmanager --list` и наличие `platforms;android-36`

## 2. Ключи проекта
Для релизной подписи создайте `android/key.properties` на своей машине и используйте собственный keystore. Не публикуйте keystore, пароль или `key.properties` в Git/ZIP.

## 3. Настройки BMT GO
Нужны реальные значения:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_MAPS_API_KEY`

Скрипты `tool/build_release.ps1` (Windows PowerShell) и `tool/build_release.sh` (Linux/macOS) запрашивают их во время сборки и не записывают в исходники.

## 4. Сборка
Windows:
`powershell -ExecutionPolicy Bypass -File .\tool\build_release.ps1`

Linux/macOS:
`./tool/build_release.sh`

Результат:
`build/app/outputs/bundle/release/app-release.aab`

## 5. Перед публикацией
1. Заменить placeholder поддержки в `docs/account_deletion.html` на реальный официальный e-mail/контакт.
2. Разместить страницу удаления аккаунта на HTTPS-адресе.
3. Проверить Privacy Policy и Google Play Data Safety под фактическое поведение приложения.
4. В Google Play Console создать/выбрать приложение BMT GO.
5. Загрузить AAB в тестовый трек, установить на Android и проверить регистрацию, заказ, геолокацию, статусы, уведомления, оплату и историю.
6. Только после теста переносить релиз в production.
