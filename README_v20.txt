BMT GO v20 — дорожный маршрут и расчёт стоимости

Что добавлено:
- Google Directions API для маршрута на автомобиле;
- расстояние по дороге и примерное время;
- цена = 1500 ₸ + 300 ₸ за каждый начатый км;
- fallback на расстояние по прямой, если API не подключён;
- карта заказа показывает точки забора/доставки и линию маршрута-превью;
- SQL: supabase/v20_routes.sql

Запуск:
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=GOOGLE_MAPS_API_KEY=...

Для настоящего дорожного маршрута включите Directions API в Google Cloud и используйте ключ с ограничениями Android/iOS.
Важно: ключ не хранится в исходниках проекта.
