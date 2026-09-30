BMT GO v26 — подготовка реальной оплаты картой

В v26 добавлено:
- интеграционный слой оплаты картой через Freedom Pay;
- Supabase Edge Function freedompay-create-payment — создаёт платёж и получает защищённый redirect URL;
- Supabase Edge Function freedompay-webhook — серверное подтверждение статуса платежа;
- в orders сохраняются payment_provider, payment_transaction_id, payment_checkout_url, payment_created_at;
- приложение открывает страницу оплаты вне приложения и не хранит данные карты;
- наличная оплата остаётся без изменений.

Важно:
- Для реального запуска нужны merchant ID и secret key Freedom Pay, а также одобренный магазин/договор.
- Секретный ключ нельзя помещать во Flutter-приложение; он должен храниться только в Supabase Edge Function secrets.
- Нужно указать BMT_GO_PUBLIC_URL и корректные success/failure/result URL.
- Точный формат подписи и параметры необходимо сверить с актуальной документацией Freedom Pay перед продакшеном.
- Это не означает, что платежи уже работают без подключения мерчанта.

Источники API:
Freedom Pay: https://docs.freedompay.kz/api-11620859
Freedom Pay Overview: https://docs.freedompay.kz/doc-741636
