BMT GO v35 — final release configuration

Изменения:
- версия обновлена до 1.13.0+35;
- добавлен scripts/pre_release_check.sh для автоматической проверки перед release;
- добавлен финальный release-чеклист v35;
- сохранены функции v34 и предыдущих версий.

Команда проверки:
  ./scripts/pre_release_check.sh

Сборка AAB на компьютере с Flutter SDK:
  flutter pub get
  flutter build appbundle --release

Важно: production keystore, Supabase secrets, Firebase release configuration и платёжные секреты не входят в архив.
