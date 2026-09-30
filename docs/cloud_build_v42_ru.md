# BMT GO v42 — сборка AAB без компьютера

## Что нужно
- телефон с браузером;
- аккаунт GitHub;
- доступ к GitHub Actions;
- реальные значения Supabase URL/anon key и Google Maps API key.

## GitHub Secrets
В репозитории откройте Settings → Secrets and variables → Actions → New repository secret.
Добавьте:
- `BMT_GO_KEYSTORE_PASSWORD` — придуманный вами длинный пароль;
- `BMT_GO_SUPABASE_URL` — URL вашего Supabase проекта;
- `BMT_GO_SUPABASE_ANON_KEY` — anon key вашего Supabase проекта;
- `BMT_GO_GOOGLE_MAPS_API_KEY` — ключ Google Maps.

Не отправляйте эти значения в чат и не вставляйте их в исходный код.

## Запуск
Откройте вкладку Actions → `BMT GO - Cloud AAB Build` → `Run workflow`.
После завершения откройте запуск и скачайте artifact `BMT-GO-v42-AAB`.

При первом запуске workflow дополнительно создаётся artifact `BMT-GO-v42-upload-key-backup`. Скачайте и храните его отдельно: внутри находится upload keystore и пароль. Не публикуйте этот архив.

## Важное ограничение
Этот workflow подготовлен для облачной сборки, но сам AAB не появляется автоматически в этом чате. Его создаёт GitHub Actions после запуска workflow.
