BMT GO v37

Версия: 1.15.0+37
compileSdk: 36
targetSdk: 36
applicationId: com.bmtgo.app

Что добавлено:
- проверка версии/SDK/подписи/файлов перед релизом;
- Windows PowerShell и Linux/macOS скрипты сборки AAB;
- отдельная проверка Android/Flutter окружения;
- инструкция Google Play на русском;
- сборка запрашивает Supabase и Google Maps значения без записи их в исходники.

Важно: AAB нельзя считать готовым, пока он реально не собран и не протестирован на машине с Flutter + Android SDK 36 и настроенной релизной подписью.
