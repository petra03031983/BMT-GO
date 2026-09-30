BMT GO v34 — Google Play account deletion web page

Добавлено:
- docs/account_deletion.html — готовая адаптивная публичная страница удаления аккаунта;
- обновлена версия приложения до 1.12.0+34;
- сохранены функции v33 и предыдущих версий.

Перед публикацией:
1. Разместить docs/account_deletion.html на публичном HTTPS-домене BMT GO.
2. Вставить официальный e-mail поддержки вместо текста-заглушки.
3. Указать фактический URL страницы удаления аккаунта в Google Play Console.
4. Проверить, что URL открывается без авторизации.
5. Выполнить Supabase SQL из supabase/v33_account_deletion.sql в production-проекте.
6. Собрать release AAB после настройки keystore, Firebase, Supabase и платежного провайдера.

Важно: этот пакет не содержит production-секретов, keystore или реальных банковских ключей.
