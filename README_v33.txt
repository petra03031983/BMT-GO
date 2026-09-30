BMT GO v33 — FINAL PREFLIGHT

Version: 1.11.0+33
Application ID: com.bmtgo.app
Target SDK: 35

Добавлено:
- in-app пункт «Удалить аккаунт»;
- Supabase table/RPC для регистрации запросов удаления;
- preflight_release.sh для проверки release-комплекта;
- обновлённый чек-лист Google Play.

Ограничение:
v33 НЕ удаляет auth.users автоматически. Запрос фиксируется на сервере, а окончательное удаление должно учитывать законные сроки хранения платежных, бухгалтерских и спорных данных. Публичная web-страница для удаления аккаунта также должна быть размещена отдельно до публикации.

Сборка:
./scripts/preflight_release.sh
./scripts/create_upload_keystore.sh
./scripts/build_release.sh
