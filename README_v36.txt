BMT GO v36 — Google Play current-target release hardening

Версия: 1.14.0+36
applicationId: com.bmtgo.app
Target/Compile SDK: Android 16 / API 36

Что изменено:
- targetSdk/compileSdk подняты с API 35 до API 36.
- versionCode 36 / versionName 1.14.0.
- Добавлен отдельный pre-release скрипт scripts/pre_release_check_v36.sh.
- Сохранены функции v35: профиль, история, выплаты, уведомления, карта, GPS, оплата и удаление аккаунта.

Сборка на компьютере с Flutter:
1. Установить Android SDK Platform 36 и Build-Tools.
2. Настроить Flutter.
3. Создать android/key.properties по примеру и собственный upload keystore.
4. Запустить: ./scripts/pre_release_check_v36.sh
5. Затем: ./scripts/build_release.sh
6. AAB появится в build/app/outputs/bundle/release/app-release.aab

Важно: Google Play с 31 августа 2026 года требует для новых приложений и обновлений Android 16/API 36 или выше. Проверьте актуальные требования перед отправкой.

Перед публикацией также нужно:
- указать настоящий HTTPS URL страницы удаления аккаунта;
- заменить контакт поддержки в docs/account_deletion.html;
- подключить реальные Supabase/Firebase/Maps/платёжные настройки;
- выполнить Data Safety и заполнить карточку приложения в Play Console.
