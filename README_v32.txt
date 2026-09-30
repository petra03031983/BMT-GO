BMT GO v32 — RELEASE SIGNING KIT

Version: 1.10.0+32
Application ID: com.bmtgo.app
Target SDK: 35

Что сделано:
- Добавлена release signing конфигурация Android.
- Добавлен безопасный шаблон android/key.properties.
- Добавлен скрипт создания собственного upload keystore.
- Добавлен скрипт сборки подписанного AAB.
- Добавлен .gitignore для ключей и секретов.

Как использовать:
1. На компьютере с Flutter открой проект.
2. Выполни: ./scripts/create_upload_keystore.sh
3. Надёжно сохрани keystore и пароли.
4. Проверь реальные Supabase/Firebase/Maps/платёжные настройки.
5. Выполни: ./scripts/build_release.sh
6. Полученный AAB будет в build/app/outputs/bundle/release/.

Важно: в этот ZIP намеренно НЕ включён реальный keystore и пароли.
Не отправляй их в чат, GitHub или Google Play Console.
