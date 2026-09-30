# BMT GO v39 — финальный путь до Google Play

## 1. На компьютере
Установить Flutter, Android Studio и Android SDK Platform 36. Проверить:

- `flutter doctor -v`
- Android SDK Platform 36
- Java, совместимую с установленным Android/Gradle окружением

## 2. Реальные данные BMT GO
Перед сборкой подготовить:
- Supabase URL
- Supabase Anon Key
- Google Maps API Key
- release keystore и `android/key.properties`

Не помещать секреты в Git и не вставлять их в исходники.

## 3. Проверка
Linux/macOS:
`./tool/check_release_gate.sh`

Windows PowerShell:
`./tool/check_release_gate.ps1`

## 4. Сборка
Windows:
`./tool/build_release.ps1`

Linux/macOS:
`./tool/build_release.sh`

Результат: `build/app/outputs/bundle/release/app-release.aab`

## 5. Перед загрузкой
Проверить на реальном Android-телефоне: регистрация, вход, создание заказа, геолокация, карта, назначение курьера, статусы, уведомления, оплата/наличные, рейтинг, история и удаление аккаунта.

## 6. Google Play Console
Создать приложение BMT GO, заполнить Store Listing, App Content, Data Safety, Privacy Policy URL и Account deletion URL. Затем загрузить AAB во внутреннее тестирование и проверить сценарии перед production.

Для новых приложений и обновлений Google Play с 31 августа 2026 года требует target Android 16 / API 36 или выше.
