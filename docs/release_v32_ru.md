# BMT GO v32 — финальный release-чеклист

## Android
- applicationId: `com.bmtgo.app`
- versionName: `1.10.0`
- versionCode: `32`
- targetSdk: `35`
- release signing: настроен через `android/key.properties`

## Перед загрузкой в Google Play
- [ ] Создать upload keystore локально.
- [ ] Сделать минимум две безопасные резервные копии keystore.
- [ ] Проверить Supabase production URL/ключи и RLS.
- [ ] Проверить Firebase/FCM production configuration.
- [ ] Ограничить Google Maps API key по package name/SHA-1.
- [ ] Подключить production payment merchant и server-side secret.
- [ ] Разместить Privacy Policy на публичном HTTPS-адресе.
- [ ] Реализовать и проверить удаление аккаунта и связанных данных.
- [ ] Заполнить Data Safety по фактическому поведению приложения.
- [ ] Подготовить иконку, скриншоты, описание и контакты разработчика.
- [ ] Собрать подписанный AAB: `./scripts/build_release.sh`.
- [ ] Установить release APK/AAB на тестовое устройство и пройти полный сценарий: регистрация → заказ → назначение → карта → доставка → оплата → рейтинг → выплата.

## Что НЕ делать
- Не загружать keystore в публичные репозитории.
- Не хранить production secret платежей внутри Flutter-кода.
- Не считать черновик Privacy Policy/Data Safety окончательным без сверки с реальными данными приложения.
