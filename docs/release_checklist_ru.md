# BMT GO v33 — финальный preflight Google Play

## Что проверено в исходниках
- applicationId: `com.bmtgo.app`
- targetSdk: 35
- release signing template без секретов в архиве
- Privacy Policy draft
- Data Safety draft
- in-app путь запроса удаления аккаунта
- SQL для регистрации запроса удаления аккаунта
- INTERNET / location / notification permissions
- `usesCleartextTraffic=false`

## Что обязательно сделать до публикации
1. Создать и безопасно сохранить собственный upload keystore.
2. Настроить `android/key.properties` только локально.
3. Настроить production Supabase, Firebase, Google Maps и платежи.
4. Разместить Privacy Policy на публичном HTTPS URL.
5. Создать публичную web-страницу, через которую пользователь сможет запросить удаление аккаунта и связанных данных.
6. Выполнить SQL `supabase/v33_account_deletion.sql` в production Supabase.
7. Настроить реальный процесс обработки запросов удаления с учётом законных сроков хранения платежных/бухгалтерских данных.
8. Заполнить Data Safety по фактическому поведению приложения и всех SDK.
9. На компьютере с Flutter выполнить `./scripts/preflight_release.sh`, затем собрать AAB.
10. Протестировать release AAB на реальном телефоне и пройти Play Console testing/review.

## Важное требование Google Play
Если приложение позволяет создавать аккаунт, Google Play требует путь удаления аккаунта внутри приложения и web-ресурс для запроса удаления аккаунта и связанных данных. Поэтому в v33 добавлен in-app запрос; публичный web-ресурс ещё нужно разместить отдельно.
