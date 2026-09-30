BMT GO v42 — CLOUD BUILD / PHONE FRIENDLY

Версия: 1.19.0+42
Application ID: com.bmtgo.app
compileSdk/targetSdk: 36

Главное изменение: добавлен GitHub Actions cloud build для сборки подписанного AAB без собственного компьютера.

Как использовать с телефона:
1. Создать GitHub-репозиторий и загрузить проект.
2. В Settings -> Secrets and variables -> Actions добавить BMT_GO_KEYSTORE_PASSWORD.
3. Для реальной сборки также добавить BMT_GO_SUPABASE_URL, BMT_GO_SUPABASE_ANON_KEY и BMT_GO_GOOGLE_MAPS_API_KEY.
4. Открыть Actions -> BMT GO - Cloud AAB Build -> Run workflow.
5. После успешной сборки скачать artifact BMT-GO-v42-AAB.
6. При первом запуске workflow также скачать BMT-GO-v42-upload-key-backup и сохранить его в безопасном месте. Этот ключ нужен для будущих обновлений.

Важно: GitHub Actions выполняет сборку в облаке. Собственные Flutter/Android SDK на телефоне не нужны.
