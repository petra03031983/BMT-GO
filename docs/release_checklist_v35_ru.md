# BMT GO v35 — финальный release-чеклист

## Что проверено в исходниках
- Версия приложения: **1.13.0+35**
- Application ID: **com.bmtgo.app**
- Target SDK: **35**
- `android:key.properties` и keystore исключены из Git/архива шаблоном `.gitignore`
- Manifest содержит Internet, GPS и POST_NOTIFICATIONS
- Cleartext HTTP отключён
- Privacy Policy и Account Deletion страницы присутствуют
- Pre-release script проверяет обязательные файлы, версию и очевидные placeholders/secrets

## Что нужно сделать владельцу проекта перед загрузкой
1. Вставить production Supabase URL/anon key.
2. Настроить Firebase для release и проверить `google-services.json`.
3. Настроить production-платёжный провайдер и webhook.
4. Создать/подключить собственный upload keystore и заполнить `android/key.properties` локально.
5. Выполнить все SQL-миграции Supabase в правильном порядке и проверить RLS.
6. Разместить privacy policy и account deletion на HTTPS-домене.
7. Запустить `scripts/pre_release_check.sh`.
8. На компьютере с Flutter SDK выполнить `flutter pub get` и `flutter build appbundle --release`.
9. Установить release-сборку на реальный телефон и проверить вход, заказ, GPS, уведомления, карту, оплату, историю и удаление аккаунта.
10. Только после этого загрузить AAB в Google Play Console.

## Важно
Этот архив **не содержит production-секретов и keystore**. В текущем рабочем окружении Flutter SDK отсутствует, поэтому сам AAB здесь не заявляется как собранный.
